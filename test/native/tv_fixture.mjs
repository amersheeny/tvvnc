#!/usr/bin/env node
// Loopback-only protocol fixture. Requires openssl; stdin accepts synthetic state updates.
import http from 'node:http';
import tls from 'node:tls';
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import readline from 'node:readline';
import {execFileSync} from 'node:child_process';

process.umask(0o077);
const keyDir = fs.mkdtempSync(path.join(os.tmpdir(), 'tvvnc-fixture-'));
const keyPath = path.join(keyDir, 'key.pem');
const certPath = path.join(keyDir, 'cert.pem');
execFileSync('openssl', ['req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-days', '2',
  '-keyout', keyPath, '-out', certPath, '-subj', '/CN=TV VNC fixture'], {stdio: 'ignore'});
const cert = fs.readFileSync(certPath);
const tlsOptions = {key: fs.readFileSync(keyPath), cert, requestCert: true,
  rejectUnauthorized: false, minVersion: 'TLSv1.2'};
const trusted = new Set();
const clients = new Set();
const psk = 'fixture-only';
const state = {features: 615, power: 'active', volume: 20, muted: false, target: 'speaker',
  minimum: 0, maximum: 100, input: 'extInput:hdmi?port=1', inputId: 10, content: 20,
  text: 'Example search', type: 1, options: 3, start: 14, end: 14, ignoreWake: false};
const log = value => process.stdout.write(`${JSON.stringify(value)}\n`);
const varint = value => {
  let n = BigInt.asUintN(64, BigInt(value)); const out = [];
  do { out.push(Number(n & 127n) | (n > 127n ? 128 : 0)); n >>= 7n; } while (n);
  return Buffer.from(out);
};
const scalar = (tag, value) => Buffer.concat([varint(tag * 8), varint(value)]);
const bytes = (tag, value) => {
  const data = Buffer.isBuffer(value) ? value : Buffer.from(value);
  return Buffer.concat([varint(tag * 8 + 2), varint(data.length), data]);
};
const message = (...parts) => Buffer.concat(parts);
function readVarint(data, start) {
  let value = 0n;
  for (let i = 0; i < 10; i++) {
    if (start + i >= data.length) return null;
    const b = data[start + i]; value |= BigInt(b & 127) << BigInt(i * 7);
    if (!(b & 128)) return [value, start + i + 1];
  }
  throw Error('invalid varint');
}
function fields(data) {
  const result = new Map(); let offset = 0;
  while (offset < data.length) {
    const tag = readVarint(data, offset); if (!tag) throw Error('truncated tag');
    offset = tag[1]; const number = Number(tag[0] >> 3n); const wire = Number(tag[0] & 7n);
    let value;
    if (wire === 0) { const v = readVarint(data, offset); if (!v) throw Error('truncated scalar'); [value, offset] = v; }
    else if (wire === 2) {
      const size = readVarint(data, offset); if (!size || size[0] > 65536n) throw Error('invalid length');
      offset = size[1]; const end = offset + Number(size[0]); if (end > data.length) throw Error('truncated message');
      value = data.subarray(offset, end); offset = end;
    } else throw Error('unsupported fixture wire type');
    result.set(number, [...(result.get(number) ?? []), value]);
  }
  return result;
}
const first = (m, tag) => m.get(tag)?.[0];
const integer = (m, tag, fallback = 0) => first(m, tag) === undefined ? fallback : Number(BigInt.asIntN(32, first(m, tag)));
const string = (m, tag) => first(m, tag)?.toString('utf8') ?? '';
const nested = (m, tag) => fields(first(m, tag) ?? Buffer.alloc(0));
function framed(socket, callback) {
  let input = Buffer.alloc(0);
  socket.on('error', () => {});
  socket.on('data', chunk => {
    try {
      input = Buffer.concat([input, chunk]);
      if (input.length > 131072) throw Error('oversized frame');
      for (;;) {
        const size = readVarint(input, 0); if (!size) return;
        if (size[0] > 65536n) throw Error('oversized frame');
        const end = size[1] + Number(size[0]); if (input.length < end) return;
        const packet = input.subarray(size[1], end); input = input.subarray(end);
        callback(fields(packet));
        if (!input.length) return;
      }
    } catch { socket.destroy(); log({error: 'invalid fixture request'}); }
  });
}
const send = (socket, packet) => socket.write(message(varint(packet.length), packet));
const fingerprint = raw => crypto.createHash('sha256').update(raw).digest('hex');
const rsa = raw => { const k = new crypto.X509Certificate(raw).publicKey.export({format: 'jwk'}); return [Buffer.from(k.n, 'base64url'), Buffer.from(k.e, 'base64url')]; };
const serverRsa = rsa(cert);
const pair = tls.createServer(tlsOptions, socket => {
  const peer = socket.getPeerCertificate().raw; if (!peer) return socket.destroy();
  const nonce = crypto.randomBytes(2);
  const secret = crypto.createHash('sha256').update(Buffer.concat([...rsa(peer), ...serverRsa, nonce])).digest();
  const code = Buffer.concat([secret.subarray(0, 1), nonce]).toString('hex').toUpperCase();
  const reply = part => send(socket, message(scalar(1, 2), scalar(2, 200), part));
  framed(socket, m => {
    if (m.has(10)) reply(bytes(11, bytes(1, 'TV VNC fixture')));
    else if (m.has(20)) reply(bytes(20, message(bytes(2, message(scalar(1, 3), scalar(2, 6))), scalar(3, 2))));
    else if (m.has(30)) { reply(bytes(31, Buffer.alloc(0))); log({pairingCode: code}); }
    else if (m.has(40)) {
      const received = first(nested(m, 40), 1);
      if (!received || received.length !== secret.length || !crypto.timingSafeEqual(received, secret)) return socket.destroy();
      trusted.add(fingerprint(peer)); reply(bytes(41, bytes(1, secret))); log({paired: true});
    }
  });
});
function editor(socket) {
  const info = message(scalar(1, state.inputId), scalar(2, state.type), scalar(3, state.options), bytes(12, 'fixture.tv'));
  send(socket, bytes(20, message(bytes(1, info), bytes(2, textStatus()))));
  send(socket, bytes(21, message(scalar(1, 1), scalar(2, 1))));
}
function textStatus() {
  return message(scalar(1, state.content), bytes(2, state.text), scalar(3, state.start), scalar(4, state.end), bytes(6, 'Fixture field'));
}
function volume(socket) {
  send(socket, bytes(50, message(scalar(1, 12), scalar(2, 1), bytes(3, 'Fixture output'), scalar(4, 2),
    scalar(5, state.minimum ?? 0), scalar(6, state.maximum ?? 100), scalar(7, state.volume), scalar(8, +state.muted))));
}
function broadcast() {
  for (const socket of clients) {
    send(socket, bytes(40, scalar(1, +(state.power === 'active'))));
    if (state.features & 64) volume(socket);
  }
}
function configure(socket) {
  send(socket, bytes(1, message(scalar(1, state.features), bytes(2, message(bytes(1, 'Protocol TV fixture'), bytes(2, 'Sony'), bytes(6, 'fixture'))))));
}
const remote = tls.createServer(tlsOptions, socket => {
  const peer = socket.getPeerCertificate().raw;
  if (!peer || !trusted.has(fingerprint(peer))) return socket.destroy();
  clients.add(socket);
  let pingId = 0;
  const ping = setInterval(() => send(socket, bytes(8, scalar(1, ++pingId))), 5000);
  socket.on('close', () => { clients.delete(socket); clearInterval(ping); });
  configure(socket);
  framed(socket, m => {
    if (m.has(1)) { send(socket, bytes(2, scalar(1, state.features))); }
    if (m.has(2)) { broadcast(); if (state.features & 4) editor(socket); }
    if (m.has(10)) {
      const key = integer(nested(m, 10), 1); const direction = integer(nested(m, 10), 2);
      log({key, direction});
      if (direction === 3) {
        if (key === 24) state.volume = Math.min(state.maximum, state.volume + 1);
        if (key === 25) state.volume = Math.max(state.minimum, state.volume - 1);
        if (key === 164) state.muted = !state.muted;
        if (key === 26) state.power = state.power === 'active' ? 'standby' : 'active';
        broadcast();
      }
    }
    if (m.has(21)) {
      const batch = nested(m, 21); if (integer(batch, 1) !== state.inputId) return;
      for (const raw of batch.get(3) ?? []) {
        const edit = fields(raw);
        if (edit.has(2)) {
          const replacement = nested(edit, 2); const start = integer(replacement, 1); const end = integer(replacement, 2);
          state.text = state.text.slice(0, start) + string(replacement, 3) + state.text.slice(end);
          state.start = state.end = start + string(replacement, 3).length; state.content++;
        }
        if (edit.has(1)) { const selection = nested(edit, 1); state.start = integer(selection, 1); state.end = integer(selection, 2); }
        if (edit.has(5)) log({editorAction: integer(nested(edit, 5), 1)});
      }
      send(socket, bytes(22, bytes(2, textStatus())));
      send(socket, bytes(23, message(scalar(1, state.start), scalar(2, state.end))));
      log({editLength: state.text.length, selection: [state.start, state.end]});
    }
    if (m.has(50)) { const v = nested(m, 50); if (integer(v, 1) !== 12) return;
      if (v.has(2)) state.volume = integer(v, 2); if (v.has(3)) state.muted = !!integer(v, 3); broadcast(); }
    if (m.has(51)) { const v = nested(m, 51); if (integer(v, 1) !== 12) return;
      const d = integer(v, 2); if (d === 2) state.muted = !state.muted;
      else state.volume = Math.max(state.minimum, Math.min(state.maximum, state.volume + (d === 0 ? 1 : -1)));
      log({adjustDirection: d}); broadcast(); }
  });
});
const methods = {
  system: ['getPowerStatus', 'setPowerStatus', 'getRemoteControllerInfo', 'getSystemInformation', 'getInterfaceInformation', 'getNetworkSettings'],
  audio: ['getVolumeInformation', 'setAudioVolume', 'setAudioMute'],
  avContent: ['getCurrentExternalInputsStatus', 'getPlayingContentInfo', 'setPlayContent'],
  appControl: ['getApplicationList', 'setActiveApp'],
};
const buttons = ['Power', 'Home', 'Return', 'Confirm', 'Up', 'Down', 'Left', 'Right', 'VolumeUp', 'VolumeDown', 'Mute', 'Tv', 'Hdmi1', 'Hdmi2'];
const api = http.createServer((req, res) => {
  let body = ''; req.on('data', chunk => { body += chunk; if (body.length > 65536) req.destroy(); });
  req.on('end', () => {
    try {
      if (req.method !== 'POST') { res.writeHead(405).end(); return; }
      if (req.url === '/sony/IRCC') {
        if (req.headers['x-auth-psk'] !== psk) { res.writeHead(403).end(); return; }
        const code = body.match(/<IRCCCode>([^<]+)<\/IRCCCode>/)?.[1];
        const key = Buffer.from(code ?? '', 'base64').toString();
        if (key === 'Power') state.power = state.power === 'active' ? 'standby' : 'active';
        broadcast(); res.writeHead(200, {'Content-Type': 'text/xml'}).end('<ok/>'); return;
      }
      const q = JSON.parse(body); const service = req.url.split('/').at(-1); const arg = q.params?.[0] ?? {};
      if (q.method?.startsWith('set') && req.headers['x-auth-psk'] !== psk) { res.writeHead(403).end(); return; }
      let result = [];
      switch (q.method) {
        case 'getVersions': result = [['1.0']]; break;
        case 'getMethodTypes': result = (methods[service] ?? []).map(name => [name, [], [], '1.0']); break;
        case 'getPowerStatus': result = [{status: state.power}]; break;
        case 'setPowerStatus': if (!arg.status || !state.ignoreWake) state.power = arg.status ? 'active' : 'standby'; broadcast(); break;
        case 'getRemoteControllerInfo': result = [{}, buttons.map(name => ({name, value: Buffer.from(name).toString('base64')}))]; break;
        case 'getSystemInformation': result = [{model: 'Protocol TV fixture', softwareVersion: 'fixture'}]; break;
        case 'getInterfaceInformation': result = [{modelName: 'Protocol TV fixture'}]; break;
        case 'getNetworkSettings': result = [[]]; break;
        case 'getVolumeInformation': result = [[{target: state.target, volume: state.volume, mute: state.muted,
          ...(state.minimum === null ? {} : {minVolume: state.minimum}), ...(state.maximum === null ? {} : {maxVolume: state.maximum})}]]; break;
        case 'setAudioVolume': if (arg.target !== state.target) throw Error('wrong target'); state.volume = Number(arg.volume); broadcast(); break;
        case 'setAudioMute': state.muted = !!arg.status; broadcast(); break;
        case 'getCurrentExternalInputsStatus': result = [[1, 2].map(port => ({uri: `extInput:hdmi?port=${port}`, title: `HDMI ${port}`, label: 'Fixture device', connection: true}))]; break;
        case 'getPlayingContentInfo': result = [{uri: state.input}]; break;
        case 'setPlayContent': state.input = arg.uri; break;
        case 'getApplicationList': result = [[{uri: 'fixture:app', title: 'Fixture app'}]]; break;
        case 'setActiveApp': break;
        default: res.writeHead(200, {'Content-Type': 'application/json'}).end(JSON.stringify({id: q.id, error: [3, 'Unsupported fixture method']})); return;
      }
      res.writeHead(200, {'Content-Type': 'application/json'}).end(JSON.stringify({id: q.id, result}));
    } catch { res.writeHead(400).end(); }
  });
});
for (const server of [pair, remote]) server.on('tlsClientError', () => {});
let listening = 0;
for (const [server, port] of [[pair, 6467], [remote, 6466], [api, 18080]]) {
  server.on('error', error => { log({error: error.code, port}); process.exit(1); });
  server.listen(port, '127.0.0.1', () => {
    if (++listening === 3) log({ready: true, host: '127.0.0.1', ports: [18080, 6466, 6467]});
  });
}
process.on('SIGTERM', () => process.exit(0));
process.on('SIGINT', () => process.exit(0));
readline.createInterface({input: process.stdin}).on('line', line => {
  if (line === 'quit') return process.exit(0);
  try {
    const change = JSON.parse(line); Object.assign(state, change);
    if ('text' in change || 'type' in change || 'options' in change) {
      state.inputId++; state.content++; state.start = state.end = state.text.length;
      for (const socket of clients) editor(socket);
    }
    if ('features' in change) for (const socket of clients) configure(socket);
    broadcast(); log({updated: Object.keys(change)});
  } catch { log({error: 'invalid fixture update'}); }
});
process.on('exit', () => fs.rmSync(keyDir, {recursive: true, force: true}));

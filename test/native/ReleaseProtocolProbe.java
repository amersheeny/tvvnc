import java.lang.reflect.*;
import java.util.*;
import javax.net.ssl.*;

/** Runs against the exact minified APK on Android ART, not an unshrunk JVM jar.
 * Class/method names are supplied from that build's R8 mapping. No app storage,
 * network connection, credential or TV operation is accessed. */
public final class ReleaseProtocolProbe {
  private static final java.io.PrintStream OUT = new java.io.PrintStream(new java.io.FileOutputStream(java.io.FileDescriptor.out));
  public static void main(String[] args) throws Exception {
    Thread.setDefaultUncaughtExceptionHandler((thread, error) -> { error.printStackTrace(OUT); System.exit(1); });
    Class<?> enumType = Class.forName(args[2]);
    Object[] values = enumType.getEnumConstants();
    if (values == null) throw new AssertionError("enum constants unavailable");
    List<String> names = new ArrayList<>();
    for (Object value : values) names.add(((Enum<?>) value).name());
    if (!new TreeSet<>(names).equals(new TreeSet<>(Arrays.asList("WAKE", "HOME", "WAIT_FOR_TV", "INPUT", "APP", "KEY", "SONY"))))
      throw new AssertionError("persisted action names changed: " + names);
    OUT.println("ENUM " + names);
    int failures = 0;
    for (int i = 0; i < 2; ++i) {
      Class<?> type = Class.forName(args[i]);
      Object instance = null;
      for (Field field : type.getDeclaredFields()) {
        if (Modifier.isStatic(field.getModifiers()) && field.getType() == type) {
          field.setAccessible(true); instance = field.get(null); break;
        }
      }
      if (instance == null) throw new AssertionError("default instance missing");
      Method serialize = null;
      for (Class<?> parent = type; parent != null && serialize == null; parent = parent.getSuperclass()) {
        for (Method method : parent.getDeclaredMethods()) {
          if (!Modifier.isStatic(method.getModifiers()) && method.getParameterCount() == 0 && method.getReturnType() == byte[].class) {
            serialize = method; break;
          }
        }
      }
      if (serialize == null) throw new AssertionError("serializer missing");
      serialize.setAccessible(true);
      try {
        byte[] wire = (byte[]) serialize.invoke(instance);
        OUT.println("SERIALIZE " + type.getName() + " bytes=" + wire.length);
        Method parse = type.getDeclaredMethod("parseFrom", byte[].class);
        String[] fixtures = i == 0 ? new String[] { "520408031001", "520408031002", "520408031003" }
            : new String[] { "080210c80152170a0961747672656d6f7465120a545620436f6e736f6c65", "080210c801ca0200" };
        for (String fixture : fixtures) {
          byte[] input = new byte[fixture.length()/2];
          for (int n=0; n<input.length; n++) input[n]=(byte)Integer.parseInt(fixture.substring(n*2,n*2+2),16);
          // Production pairing intentionally accepts an omitted required
          // SecretAck.secret via mergeFrom/buildPartial. Strict parseFrom is
          // not its oracle for that documented service variant.
          Object parsed;
          if (i == 1 && fixture.equals("080210c801ca0200")) {
            Method receive = null;
            for (Method candidate : Class.forName(args[3]).getDeclaredMethods()) {
              if (Modifier.isStatic(candidate.getModifiers()) && candidate.getReturnType() == type &&
                  candidate.getParameterCount() == 3 && candidate.getParameterTypes()[0] == SSLSocket.class) {
                receive = candidate; break;
              }
            }
            if (receive == null) throw new AssertionError("production pairing decoder missing");
            receive.setAccessible(true);
            Class<?> phaseType = receive.getParameterTypes()[1];
            // R8 can inline every BooleanRef construction and remove its
            // constructor. The probe needs only its zero-initialized boolean;
            // allocate that fixture without changing production keep rules.
            Class<?> unsafeType = Class.forName("sun.misc.Unsafe");
            Field singleton = unsafeType.getDeclaredField("theUnsafe");
            singleton.setAccessible(true);
            Object phase = unsafeType.getMethod("allocateInstance", Class.class)
                .invoke(singleton.get(null), phaseType);
            Class<?> predicateType = receive.getParameterTypes()[2];
            Object predicate = Proxy.newProxyInstance(predicateType.getClassLoader(), new Class<?>[] { predicateType },
                (proxy, method, arguments) -> Boolean.TRUE);
            byte[] frame = new byte[input.length + 1]; frame[0] = (byte) input.length;
            System.arraycopy(input, 0, frame, 1, input.length);
            parsed = receive.invoke(null, new FixtureSocket(frame), phase, predicate);
            if (!Boolean.TRUE.equals(type.getMethod("hasSecretAck").invoke(parsed))) throw new AssertionError("ack missing");
            // Same STATUS_ERROR before code entry and after secret submission
            // must not produce the same user-facing cause.
            byte[] refused = {7, 8, 2, 16, (byte) 0x90, 3, 0x5a, 0};
            assertPairFailure(receive, new FixtureSocket(refused), phase, predicate, "pairing_unavailable");
            Field phaseField = null;
            for (Field field : phaseType.getDeclaredFields()) {
              if (!Modifier.isStatic(field.getModifiers()) && field.getType() == boolean.class) {
                if (phaseField != null) throw new AssertionError("ambiguous pairing phase");
                phaseField = field;
              }
            }
            if (phaseField == null) throw new AssertionError("pairing phase missing");
            phaseField.setAccessible(true); phaseField.setBoolean(phase, true);
            assertPairFailure(receive, new FixtureSocket(refused), phase, predicate, "pairing_rejected");
            OUT.println("PAIRING phase-specific rejection fixtures=2");
          } else parsed = parse.invoke(null, (Object) input);
          if (!Arrays.equals(input, (byte[]) serialize.invoke(parsed))) throw new AssertionError("wire mismatch");
        }
        OUT.println("ROUNDTRIP " + type.getName() + " fixtures=" + fixtures.length);
      } catch (InvocationTargetException error) {
        ++failures;
        OUT.println("FAIL " + type.getName() + " " + error.getCause());
      }
    }
    System.exit(failures == 0 ? 0 : 1);
  }
  private static void assertPairFailure(Method receive, SSLSocket socket, Object phase,
      Object predicate, String expected) throws Exception {
    try {
      receive.invoke(null, socket, phase, predicate);
      throw new AssertionError("pairing rejection accepted");
    } catch (InvocationTargetException error) {
      if (!expected.equals(error.getCause().getMessage())) throw error;
    }
  }
  /** Only a framed input source for the real minified receive function. This
   * does not simulate or claim to test a TLS handshake. */
  private static final class FixtureSocket extends SSLSocket {
    private final java.io.InputStream input;
    FixtureSocket(byte[] frame) { input = new java.io.ByteArrayInputStream(frame); }
    public java.io.InputStream getInputStream() { return input; }
    public void setSoTimeout(int timeout) { }
    public String[] getSupportedCipherSuites() { throw new UnsupportedOperationException(); }
    public String[] getEnabledCipherSuites() { throw new UnsupportedOperationException(); }
    public void setEnabledCipherSuites(String[] suites) { throw new UnsupportedOperationException(); }
    public String[] getSupportedProtocols() { throw new UnsupportedOperationException(); }
    public String[] getEnabledProtocols() { throw new UnsupportedOperationException(); }
    public void setEnabledProtocols(String[] protocols) { throw new UnsupportedOperationException(); }
    public SSLSession getSession() { throw new UnsupportedOperationException(); }
    public void addHandshakeCompletedListener(HandshakeCompletedListener listener) { throw new UnsupportedOperationException(); }
    public void removeHandshakeCompletedListener(HandshakeCompletedListener listener) { throw new UnsupportedOperationException(); }
    public void startHandshake() { throw new UnsupportedOperationException(); }
    public void setUseClientMode(boolean value) { throw new UnsupportedOperationException(); }
    public boolean getUseClientMode() { throw new UnsupportedOperationException(); }
    public void setNeedClientAuth(boolean value) { throw new UnsupportedOperationException(); }
    public boolean getNeedClientAuth() { throw new UnsupportedOperationException(); }
    public void setWantClientAuth(boolean value) { throw new UnsupportedOperationException(); }
    public boolean getWantClientAuth() { throw new UnsupportedOperationException(); }
    public void setEnableSessionCreation(boolean value) { throw new UnsupportedOperationException(); }
    public boolean getEnableSessionCreation() { throw new UnsupportedOperationException(); }
  }
}

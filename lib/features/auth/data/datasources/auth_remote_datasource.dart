import '../../domain/entities/user.dart';

class AuthRemoteDataSource {
  // Aquí inyectarías tu cliente HTTP (ej. DioClient desde core/network)
  // final NetworkClient networkClient;
  // AuthRemoteDataSource(this.networkClient);

  Future<User> login(String email, String password) async {
    // TODO: Reemplazar con llamada real a la API
    await Future.delayed(const Duration(seconds: 2));

    // Simulación de éxito
    return User(id: '1', email: email, name: 'Estudiante Tinta');
  }

  Future<User> register(String name, String email, String password) async {
    // TODO: Reemplazar con llamada real a la API
    await Future.delayed(const Duration(seconds: 2));

    return User(id: '2', email: email, name: name);
  }
}
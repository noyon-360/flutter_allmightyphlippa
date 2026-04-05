import 'package:flutter_almightyflippa/core/api/network_result.dart';
import '../../playlist/models/server_request_model.dart';
import '../models/genre_model.dart';

abstract class GenreRepo {
  NetworkResult<List<GenreModel>> getGenres(ServerType type);

  NetworkResult<List<T>> getGenresById<T>({
    required String id,
    required ServerType type,
  });
}

import '../../../core/api/network_result.dart';
import '../models/movie_response_model.dart';

abstract class MovieRepo {
  NetworkResult<List<MovieResponseModel>> getMovies();
}
import '../../../core/api/network_result.dart';
import '../models/movie_response_model.dart';
import '../models/single_movie_response_model.dart';

abstract class MovieRepo {
  NetworkResult<List<MoviesResponseModel>> getMovies({
    required int page,
    required int limit,
  });

  NetworkResult<SingleMovieResponseModel> getMovieDetails({
    required int streamId,
  });
}

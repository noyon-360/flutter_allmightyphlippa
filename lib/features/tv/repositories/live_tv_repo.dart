import 'package:flutter_almightyflippa/core/api/network_result.dart';

import '../models/live_tv_reponse_model.dart';
import '../models/single_live_tv_reponse_model.dart';

abstract class LiveTvRepo {
  NetworkResult<List<LiveTvModel>> getLiveTVList({
    required int page,
    required int limit,
  });
  NetworkResult<SingleLiveTvResponseModel> getSingleLiveTV({
    required int streamId,
  });
}

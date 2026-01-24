class SingleLiveTvResponseModel {
  final SingleLiveTvData data;
  final String playUrl;

  SingleLiveTvResponseModel({required this.data, required this.playUrl});

  factory SingleLiveTvResponseModel.fromJson(Map<String, dynamic> json) {
    return SingleLiveTvResponseModel(
      data: SingleLiveTvData.fromJson(json['data'] ?? {}),
      playUrl: json['playUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'data': data.toJson(), 'playUrl': playUrl};
  }
}

class SingleLiveTvData {
  final List<dynamic> info;

  SingleLiveTvData({required this.info});

  factory SingleLiveTvData.fromJson(Map<String, dynamic> json) {
    return SingleLiveTvData(info: json['info'] ?? []);
  }

  Map<String, dynamic> toJson() {
    return {'info': info};
  }
}

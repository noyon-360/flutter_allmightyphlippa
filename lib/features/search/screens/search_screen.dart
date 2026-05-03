import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../playlist/models/server_request_model.dart';
import '../controllers/search_controller.dart' as sc;
import '../widgets/movie_series_item_widget.dart';

class SearchScreen extends StatefulWidget {
  final ServerType type;
  const SearchScreen({super.key, required this.type});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = Get.find<sc.SearchingController>();
  late sc.SearchState _state;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _state = _searchCtrl.getState(widget.type);
    _scrollController.addListener(_onScroll);
    _textController.text = _state.query.value;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _searchCtrl.searchData(type: widget.type, isLoadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryWhite),
          onPressed: () => Get.back(),
        ),
        title: TextField(
          controller: _textController,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (val) => _searchCtrl.onQueryChanged(val, widget.type),
          onSubmitted: (val) => _searchCtrl.searchData(type: widget.type),
          style: const TextStyle(color: AppColors.primaryWhite),
          cursorColor: AppColors.red,
          decoration: const InputDecoration(
            hintText: 'Search movies, series...',
            hintStyle: TextStyle(color: AppColors.hintText),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        actions: [
          Obx(
            () => _state.query.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: AppColors.primaryWhite,
                    ),
                    onPressed: () {
                      _textController.clear();
                      _searchCtrl.onQueryChanged('', widget.type);
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Obx(() {
        if (_state.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.red),
          );
        }

        // 1. Initial State: User hasn't hit Enter yet
        if (!_state.hasSearched.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 80,
                  color: AppColors.primaryGray.withAlpha(100),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Search for your favorites',
                  style: TextStyle(
                    color: AppColors.primaryGray,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter a movie or series name above',
                  style: TextStyle(color: AppColors.hintText, fontSize: 14),
                ),
              ],
            ),
          );
        }

        // 2. Empty Results State: User hit Enter but nothing found
        if (_state.results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No results found for "${_state.query.value}"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primaryWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Try searching for something else',
                  style: TextStyle(color: AppColors.primaryGray),
                ),
              ],
            ),
          );
        }

        // 3. Results Found State
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(top: 8, bottom: 20),
          itemCount:
              _state.results.length + (_state.isMoreLoading.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < _state.results.length) {
              return MovieSeriesItemWidget(
                item: _state.results[index],
                type: widget.type,
              );
            } else {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.red),
                ),
              );
            }
          },
        );
      }),
    );
  }
}

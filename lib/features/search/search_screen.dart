// 검색 화면. 입력창 + 결과 목록 / 초기 상태 / 결과 없음.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/stock_repository.dart';
import '../../models/stock.dart';
import '../../state/favorites.dart';
import '../../theme/theme.dart';
import '../common/empty_state.dart';
import '../detail/detail_screen.dart';
import 'favorite_toast.dart';
import 'search_result_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.repo, required this.favorites});

  final StockRepository repo;
  final Favorites favorites;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  /// 타이핑이 멈춘 뒤에 요청한다. 한 글자마다 호출하면 금방 차단당한다.
  static const _debounce = Duration(milliseconds: 300);

  final TextEditingController _controller = TextEditingController();
  Timer? _timer;

  String _query = '';
  List<Stock> _results = const [];

  /// 한 번이라도 검색을 마쳤는지. 아직이면 '결과 없음' 대신 초기 상태를 둔다.
  bool _searched = false;

  /// 마지막 요청이 실패했는지.
  bool _error = false;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _query = value);
    _timer?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = const [];
        _searched = false;
        _error = false;
      });
      return;
    }
    _timer = Timer(_debounce, () => _search(value));
  }

  Future<void> _search(String value) async {
    try {
      final found = await widget.repo.search(value);
      if (!mounted || value != _controller.text) return; // 늦게 온 응답은 버린다
      setState(() {
        _results = found;
        _searched = true;
        _error = false;
      });
    } catch (_) {
      if (!mounted || value != _controller.text) return;
      // 잡지 않으면 결과 0개짜리 목록, 즉 백지가 그려진다.
      setState(() {
        _results = const [];
        _searched = true;
        _error = true;
      });
    }
  }

  void _clear() {
    _controller.clear();
    _onChanged('');
  }

  void _toggle(Stock stock) {
    final added = widget.favorites.toggle(stock);
    showFavoriteToast(context, added: added);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _SearchField(
            controller: _controller,
            onChanged: _onChanged,
            onClear: _clear,
          ),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_query.trim().isEmpty) {
      return EmptyState(
        icon: Icons.search,
        iconColor: context.colors.textDisabled,
        title: '종목을 검색해 보세요',
        description: '종목명 또는 종목코드 6자리로\n검색하실 수 있습니다.',
      );
    }

    if (_error) {
      return EmptyState(
        icon: Icons.cloud_off,
        iconColor: context.colors.textDisabled,
        title: '검색에 실패했습니다',
        description: '네트워크 상태를 확인한 뒤\n다시 시도해 주세요.',
        onRetry: () => _search(_controller.text),
      );
    }

    if (_searched && _results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        iconColor: context.colors.textDisabled,
        title: '검색 결과가 없습니다',
        description: "'$_shortQuery'와\n일치하는 검색 결과를 찾지 못했습니다.",
      );
    }

    return ListenableBuilder(
      listenable: widget.favorites,
      builder: (context, _) => ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: _results.length,
        separatorBuilder: (context, _) => Divider(
          height: context.dimens.borderHairline,
          thickness: context.dimens.borderHairline,
          color: context.colors.borderSubtle,
        ),
        itemBuilder: (context, i) => SearchResultTile(
          stock: _results[i],
          query: _query.trim(),
          isFavorite: widget.favorites.contains(_results[i].symbol),
          onToggleFavorite: () => _toggle(_results[i]),
          onTap: () => openDetail(
            context,
            stock: _results[i],
            repo: widget.repo,
            favorites: widget.favorites,
          ),
        ),
      ),
    );
  }

  /// 검색어가 아주 길 때 빈 상태 문구가 화면을 덮지 않도록 줄인다.
  /// 시안에 정의가 없어 직접 정한 규칙(20자).
  String get _shortQuery {
    final q = _query.trim();
    return q.length > 20 ? '${q.substring(0, 20)}…' : q;
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Padding(
      padding: EdgeInsets.all(dimens.space4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 15,
          fontWeight: AppTypography.regular,
        ),
        cursorColor: colors.accentDefault,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: colors.surfaceSunken,
          hintText: '종목명 또는 종목코드',
          hintStyle: TextStyle(
            color: colors.textTertiary,
            fontSize: 15,
            fontWeight: AppTypography.regular,
          ),
          // 기본 prefixIcon 은 48px 상자를 차지해 아이콘과 글자가 멀어진다.
          prefixIconConstraints: BoxConstraints(minWidth: dimens.space6 * 2),
          prefixIcon: Icon(
            Icons.search,
            size: dimens.iconMd,
            color: colors.textTertiary,
          ),
          suffixIcon: IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close),
            iconSize: dimens.iconMd,
            color: colors.textTertiary,
            tooltip: '지우기',
          ),
          contentPadding: EdgeInsets.symmetric(vertical: dimens.space3),
          border: _border(colors.borderSubtle, dimens),
          enabledBorder: _border(colors.borderSubtle, dimens),
          focusedBorder: _border(colors.borderStrong, dimens),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, AppDimens dimens) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(dimens.radiusMd),
      borderSide: BorderSide(color: color, width: dimens.borderHairline),
    );
  }
}

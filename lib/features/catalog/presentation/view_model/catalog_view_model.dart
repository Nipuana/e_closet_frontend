import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/brand_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/catalog_usecases.dart';

enum CatalogStatus { initial, loading, loaded, error }

class CatalogState extends Equatable {
  final CatalogStatus status;
  final List<CategoryEntity> categories;
  final List<BrandEntity> brands;
  final String? error;

  const CatalogState({
    this.status = CatalogStatus.initial,
    this.categories = const [],
    this.brands = const [],
    this.error,
  });

  CatalogState copyWith({
    CatalogStatus? status,
    List<CategoryEntity>? categories,
    List<BrandEntity>? brands,
    String? error,
  }) {
    return CatalogState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      brands: brands ?? this.brands,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, categories, brands, error];
}

final catalogViewModelProvider =
    NotifierProvider<CatalogViewModel, CatalogState>(CatalogViewModel.new);

class CatalogViewModel extends Notifier<CatalogState> {
  @override
  CatalogState build() => const CatalogState();

  Future<void> load() async {
    state = state.copyWith(status: CatalogStatus.loading);
    final catRes = await ref.read(getCategoriesUsecaseProvider)();
    final brandRes = await ref.read(getBrandsUsecaseProvider)();

    final cats = catRes.getOrElse(() => const []);
    final brs = brandRes.getOrElse(() => const []);
    final failed = catRes.isLeft() && brandRes.isLeft();

    state = state.copyWith(
      status: failed ? CatalogStatus.error : CatalogStatus.loaded,
      categories: cats,
      brands: brs,
      error: failed ? 'Could not load categories or brands' : null,
    );
  }

  /// Creates a user category and appends it; returns its name on success.
  Future<String?> addCategory(String name) async {
    final res = await ref.read(createCategoryUsecaseProvider)(name);
    return res.fold(
      (f) {
        state = state.copyWith(error: f.message);
        return null;
      },
      (cat) {
        if (!state.categories.any((c) => c.name.toLowerCase() == cat.name.toLowerCase())) {
          state = state.copyWith(categories: [...state.categories, cat]);
        }
        return cat.name;
      },
    );
  }

  /// Creates a user brand and appends it; returns its name on success.
  Future<String?> addBrand(String name) async {
    final res = await ref.read(createBrandUsecaseProvider)(name);
    return res.fold(
      (f) {
        state = state.copyWith(error: f.message);
        return null;
      },
      (brand) {
        if (!state.brands.any((b) => b.name.toLowerCase() == brand.name.toLowerCase())) {
          state = state.copyWith(brands: [...state.brands, brand]);
        }
        return brand.name;
      },
    );
  }
}

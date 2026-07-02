import 'package:equatable/equatable.dart';

import '../../domain/entities/wardrobe_item_entity.dart';

enum WardrobeStatus { initial, loading, loaded, error }

class WardrobeState extends Equatable {
  final WardrobeStatus allStatus;
  final WardrobeStatus recentStatus;
  final WardrobeStatus favoritesStatus;
  final List<WardrobeItemEntity> allItems;
  final List<WardrobeItemEntity> recentItems;
  final List<WardrobeItemEntity> favoriteItems;
  final String? errorMessage;

  const WardrobeState({
    this.allStatus = WardrobeStatus.initial,
    this.recentStatus = WardrobeStatus.initial,
    this.favoritesStatus = WardrobeStatus.initial,
    this.allItems = const [],
    this.recentItems = const [],
    this.favoriteItems = const [],
    this.errorMessage,
  });

  WardrobeState copyWith({
    WardrobeStatus? allStatus,
    WardrobeStatus? recentStatus,
    WardrobeStatus? favoritesStatus,
    List<WardrobeItemEntity>? allItems,
    List<WardrobeItemEntity>? recentItems,
    List<WardrobeItemEntity>? favoriteItems,
    String? errorMessage,
  }) {
    return WardrobeState(
      allStatus: allStatus ?? this.allStatus,
      recentStatus: recentStatus ?? this.recentStatus,
      favoritesStatus: favoritesStatus ?? this.favoritesStatus,
      allItems: allItems ?? this.allItems,
      recentItems: recentItems ?? this.recentItems,
      favoriteItems: favoriteItems ?? this.favoriteItems,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        allStatus,
        recentStatus,
        favoritesStatus,
        allItems,
        recentItems,
        favoriteItems,
        errorMessage,
      ];
}

class FavoritesService {
  static final List<String> favoriteNumbers = [];

  static void addFavorite(String number) {
    final cleaned = number.trim();
    if (cleaned.isNotEmpty && !favoriteNumbers.contains(cleaned)) {
      favoriteNumbers.add(cleaned);
    }
  }

  static void removeFavorite(String number) {
    favoriteNumbers.remove(number.trim());
  }

  static bool isFavorite(String number) {
    return favoriteNumbers.contains(number.trim());
  }
}

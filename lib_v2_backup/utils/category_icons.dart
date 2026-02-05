import '../models/transaction.dart';

class CategoryIcons {
  static const Map<Category, String> _icons = {
    Category.food: '🍔',
    Category.transport: '🚗',
    Category.utilities: '💡',
    Category.entertainment: '🎬',
    Category.shopping: '🛍️',
    Category.health: '💪',
    Category.groceries: '🛒',
    Category.income: '💰',
    Category.education: '📚',
    Category.personalCare: '💅',
    Category.government: '🏛️',
    Category.banking: '🏦',
    Category.other: '📄',
  };

  static String getIcon(Category category) {
    return _icons[category] ?? '📄';
  }
}

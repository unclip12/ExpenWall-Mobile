import '../models/suggestion.dart';

/// Pre-populated common suggestions for autocomplete
/// Includes popular Indian food items, categories, merchants, etc.
class CommonSuggestions {
  // Food items - Popular Indian dishes
  static final List<Suggestion> foodItems = [
    // Biryani & Rice
    Suggestion(text: 'Chicken Biryani', category: 'food', usageCount: 1000),
    Suggestion(text: 'Mutton Biryani', category: 'food', usageCount: 900),
    Suggestion(text: 'Veg Biryani', category: 'food', usageCount: 800),
    Suggestion(text: 'Egg Biryani', category: 'food', usageCount: 700),
    Suggestion(text: 'Prawn Biryani', category: 'food', usageCount: 600),
    Suggestion(text: 'Hyderabadi Biryani', category: 'food', usageCount: 950),
    Suggestion(text: 'Fried Rice', category: 'food', usageCount: 500),
    Suggestion(text: 'Jeera Rice', category: 'food', usageCount: 400),

    // Chicken dishes
    Suggestion(text: 'Chicken 65', category: 'food', usageCount: 850),
    Suggestion(text: 'Chicken Tikka', category: 'food', usageCount: 750),
    Suggestion(text: 'Chicken Curry', category: 'food', usageCount: 800),
    Suggestion(text: 'Chicken Korma', category: 'food', usageCount: 700),
    Suggestion(text: 'Butter Chicken', category: 'food', usageCount: 900),
    Suggestion(text: 'Tandoori Chicken', category: 'food', usageCount: 850),
    Suggestion(text: 'Chicken Fry', category: 'food', usageCount: 750),
    Suggestion(text: 'Chicken Kebab', category: 'food', usageCount: 650),
    Suggestion(text: 'Chicken Shawarma', category: 'food', usageCount: 800),
    Suggestion(text: 'Chicken Lollipop', category: 'food', usageCount: 700),
    Suggestion(text: 'Chicken Wings', category: 'food', usageCount: 650),
    Suggestion(text: 'Chicken Manchurian', category: 'food', usageCount: 750),

    // Snacks & Fast Food
    Suggestion(text: 'Pizza', category: 'food', usageCount: 1000),
    Suggestion(text: 'Burger', category: 'food', usageCount: 950),
    Suggestion(text: 'French Fries', category: 'food', usageCount: 800),
    Suggestion(text: 'Sandwich', category: 'food', usageCount: 750),
    Suggestion(text: 'Samosa', category: 'food', usageCount: 900),
    Suggestion(text: 'Vada Pav', category: 'food', usageCount: 850),
    Suggestion(text: 'Pani Puri', category: 'food', usageCount: 800),
    Suggestion(text: 'Dosa', category: 'food', usageCount: 950),
    Suggestion(text: 'Idli', category: 'food', usageCount: 900),
    Suggestion(text: 'Vada', category: 'food', usageCount: 850),
    Suggestion(text: 'Upma', category: 'food', usageCount: 700),
    Suggestion(text: 'Poha', category: 'food', usageCount: 750),
    Suggestion(text: 'Paratha', category: 'food', usageCount: 800),
    Suggestion(text: 'Naan', category: 'food', usageCount: 750),
    Suggestion(text: 'Roti', category: 'food', usageCount: 800),
    Suggestion(text: 'Chapati', category: 'food', usageCount: 850),

    // Curries & Gravies
    Suggestion(text: 'Paneer Butter Masala', category: 'food', usageCount: 900),
    Suggestion(text: 'Dal Makhani', category: 'food', usageCount: 850),
    Suggestion(text: 'Dal Tadka', category: 'food', usageCount: 800),
    Suggestion(text: 'Chole', category: 'food', usageCount: 750),
    Suggestion(text: 'Rajma', category: 'food', usageCount: 700),
    Suggestion(text: 'Kadai Paneer', category: 'food', usageCount: 800),
    Suggestion(text: 'Palak Paneer', category: 'food', usageCount: 750),

    // Sweets & Desserts
    Suggestion(text: 'Gulab Jamun', category: 'food', usageCount: 800),
    Suggestion(text: 'Rasgulla', category: 'food', usageCount: 750),
    Suggestion(text: 'Jalebi', category: 'food', usageCount: 700),
    Suggestion(text: 'Ice Cream', category: 'food', usageCount: 950),
    Suggestion(text: 'Cake', category: 'food', usageCount: 900),
    Suggestion(text: 'Pastry', category: 'food', usageCount: 800),
    Suggestion(text: 'Brownie', category: 'food', usageCount: 750),
    Suggestion(text: 'Chocolate', category: 'food', usageCount: 850),

    // Beverages
    Suggestion(text: 'Tea', category: 'food', usageCount: 1000),
    Suggestion(text: 'Coffee', category: 'food', usageCount: 950),
    Suggestion(text: 'Chai', category: 'food', usageCount: 1000),
    Suggestion(text: 'Cold Coffee', category: 'food', usageCount: 850),
    Suggestion(text: 'Lassi', category: 'food', usageCount: 800),
    Suggestion(text: 'Buttermilk', category: 'food', usageCount: 700),
    Suggestion(text: 'Fresh Juice', category: 'food', usageCount: 750),
    Suggestion(text: 'Soft Drink', category: 'food', usageCount: 800),
    Suggestion(text: 'Milkshake', category: 'food', usageCount: 850),

    // Chinese/Indo-Chinese
    Suggestion(text: 'Noodles', category: 'food', usageCount: 900),
    Suggestion(text: 'Fried Noodles', category: 'food', usageCount: 850),
    Suggestion(text: 'Hakka Noodles', category: 'food', usageCount: 800),
    Suggestion(text: 'Chowmein', category: 'food', usageCount: 850),
    Suggestion(text: 'Manchurian', category: 'food', usageCount: 750),
    Suggestion(text: 'Gobi Manchurian', category: 'food', usageCount: 700),
    Suggestion(text: 'Spring Roll', category: 'food', usageCount: 650),
    Suggestion(text: 'Momos', category: 'food', usageCount: 900),

    // South Indian
    Suggestion(text: 'Masala Dosa', category: 'food', usageCount: 950),
    Suggestion(text: 'Plain Dosa', category: 'food', usageCount: 900),
    Suggestion(text: 'Rava Dosa', category: 'food', usageCount: 800),
    Suggestion(text: 'Mysore Dosa', category: 'food', usageCount: 750),
    Suggestion(text: 'Uttapam', category: 'food', usageCount: 700),
    Suggestion(text: 'Medu Vada', category: 'food', usageCount: 850),
    Suggestion(text: 'Filter Coffee', category: 'food', usageCount: 900),
  ];

  // Transaction categories
  static final List<Suggestion> categories = [
    Suggestion(text: 'Food', category: 'category', usageCount: 1000),
    Suggestion(text: 'Transport', category: 'category', usageCount: 900),
    Suggestion(text: 'Shopping', category: 'category', usageCount: 850),
    Suggestion(text: 'Bills', category: 'category', usageCount: 800),
    Suggestion(text: 'Entertainment', category: 'category', usageCount: 750),
    Suggestion(text: 'Health', category: 'category', usageCount: 700),
    Suggestion(text: 'Education', category: 'category', usageCount: 650),
    Suggestion(text: 'Groceries', category: 'category', usageCount: 900),
    Suggestion(text: 'Rent', category: 'category', usageCount: 850),
    Suggestion(text: 'Utilities', category: 'category', usageCount: 800),
    Suggestion(text: 'Personal Care', category: 'category', usageCount: 700),
    Suggestion(text: 'Gifts', category: 'category', usageCount: 650),
    Suggestion(text: 'Travel', category: 'category', usageCount: 750),
    Suggestion(text: 'Subscriptions', category: 'category', usageCount: 700),
    Suggestion(text: 'Other', category: 'category', usageCount: 500),
  ];

  // Popular merchants/platforms
  static final List<Suggestion> merchants = [
    Suggestion(text: 'Swiggy', category: 'merchant', usageCount: 1000),
    Suggestion(text: 'Zomato', category: 'merchant', usageCount: 1000),
    Suggestion(text: 'Zepto', category: 'merchant', usageCount: 900),
    Suggestion(text: 'Blinkit', category: 'merchant', usageCount: 850),
    Suggestion(text: 'Amazon', category: 'merchant', usageCount: 950),
    Suggestion(text: 'Flipkart', category: 'merchant', usageCount: 950),
    Suggestion(text: 'Uber', category: 'merchant', usageCount: 800),
    Suggestion(text: 'Ola', category: 'merchant', usageCount: 800),
    Suggestion(text: 'Rapido', category: 'merchant', usageCount: 750),
    Suggestion(text: 'PhonePe', category: 'merchant', usageCount: 900),
    Suggestion(text: 'Google Pay', category: 'merchant', usageCount: 900),
    Suggestion(text: 'Paytm', category: 'merchant', usageCount: 850),
    Suggestion(text: 'Netflix', category: 'merchant', usageCount: 800),
    Suggestion(text: 'Amazon Prime', category: 'merchant', usageCount: 750),
    Suggestion(text: 'Hotstar', category: 'merchant', usageCount: 700),
    Suggestion(text: 'JioHotstar', category: 'merchant', usageCount: 750),
    Suggestion(text: 'Spotify', category: 'merchant', usageCount: 650),
    Suggestion(text: 'YouTube Premium', category: 'merchant', usageCount: 600),
  ];

  // Combined list of all suggestions
  static List<Suggestion> get all {
    return [...foodItems, ...categories, ...merchants];
  }

  // Get suggestions by category
  static List<Suggestion> getByCategory(String category) {
    return all.where((s) => s.category == category).toList();
  }
}

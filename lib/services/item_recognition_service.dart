import '../models/transaction.dart';

/// Item Recognition Service
/// Provides smart categorization and auto-suggestions for 1000+ items
/// Optimized for Indian retail context (Dmart, BigBazaar, Swiggy, Zomato, etc.)
class ItemRecognitionService {
  // Singleton pattern
  static final ItemRecognitionService _instance = ItemRecognitionService._internal();
  factory ItemRecognitionService() => _instance;
  ItemRecognitionService._internal();

  /// Get category and subcategory for an item name
  CategoryMatch? recognizeItem(String itemName) {
    final normalized = itemName.toLowerCase().trim();
    
    // Search through all categories
    for (final entry in _itemDatabase.entries) {
      for (final keyword in entry.value) {
        if (normalized.contains(keyword.toLowerCase())) {
          return CategoryMatch(
            category: entry.key.category,
            subcategory: entry.key.subcategory,
            confidence: _calculateConfidence(normalized, keyword),
            matchedKeyword: keyword,
          );
        }
      }
    }
    
    return null;
  }

  /// Get auto-suggestions as user types
  /// Returns top 10 matches with category hints
  List<ItemSuggestion> getSuggestions(String query, {int limit = 10}) {
    if (query.isEmpty) return [];
    
    final normalized = query.toLowerCase().trim();
    final suggestions = <ItemSuggestion>[];
    
    // Search through all keywords
    for (final entry in _itemDatabase.entries) {
      for (final keyword in entry.value) {
        if (keyword.toLowerCase().contains(normalized)) {
          final similarity = _calculateSimilarity(normalized, keyword.toLowerCase());
          suggestions.add(ItemSuggestion(
            itemName: keyword,
            category: entry.key.category,
            subcategory: entry.key.subcategory,
            similarity: similarity,
          ));
        }
      }
    }
    
    // Sort by similarity and return top matches
    suggestions.sort((a, b) => b.similarity.compareTo(a.similarity));
    return suggestions.take(limit).toList();
  }

  /// Recognize merchant/store and suggest category
  CategoryMatch? recognizeMerchant(String merchantName) {
    final normalized = merchantName.toLowerCase().trim();
    
    for (final entry in _merchantDatabase.entries) {
      for (final merchant in entry.value) {
        if (normalized.contains(merchant.toLowerCase())) {
          return CategoryMatch(
            category: entry.key.category,
            subcategory: entry.key.subcategory,
            confidence: 0.95, // High confidence for merchant matches
            matchedKeyword: merchant,
          );
        }
      }
    }
    
    return null;
  }

  /// Calculate confidence score (0.0 to 1.0)
  double _calculateConfidence(String input, String keyword) {
    final inputWords = input.split(' ');
    final keywordWords = keyword.toLowerCase().split(' ');
    
    int matches = 0;
    for (final kw in keywordWords) {
      if (inputWords.any((iw) => iw.contains(kw))) {
        matches++;
      }
    }
    
    return matches / keywordWords.length;
  }

  /// Calculate similarity score for suggestions
  double _calculateSimilarity(String query, String keyword) {
    // Exact match
    if (keyword == query) return 1.0;
    
    // Starts with query (high priority)
    if (keyword.startsWith(query)) return 0.9;
    
    // Contains query
    if (keyword.contains(query)) return 0.7;
    
    // Levenshtein distance based similarity
    final distance = _levenshteinDistance(query, keyword);
    return 1.0 - (distance / keyword.length.toDouble());
  }

  /// Levenshtein distance for fuzzy matching
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce((a, b) => a < b ? a : b);
      }
      List<int> temp = v0;
      v0 = v1;
      v1 = temp;
    }

    return v0[s2.length];
  }

  // ============================================================================
  // COMPREHENSIVE ITEM DATABASE (1000+ Keywords)
  // ============================================================================

  final Map<CategoryKey, List<String>> _itemDatabase = {
    // FOOD & DINING - GROCERIES (Staples)
    CategoryKey('Food & Dining', 'Groceries'): [
      'rice', 'basmati rice', 'sona masoori', 'brown rice', 'biryani rice',
      'wheat', 'atta', 'chakki atta', 'whole wheat flour', 'maida', 'refined flour',
      'besan', 'gram flour', 'chickpea flour', 'ragi flour', 'jowar flour',
      'sugar', 'jaggery', 'gur', 'brown sugar', 'honey',
      'salt', 'rock salt', 'sea salt', 'black salt', 'sendha namak',
      'oil', 'cooking oil', 'sunflower oil', 'mustard oil', 'coconut oil',
      'ghee', 'refined oil', 'olive oil', 'rice bran oil',
    ],

    // FOOD & DINING - PULSES & LENTILS
    CategoryKey('Food & Dining', 'Groceries'): [
      'dal', 'toor dal', 'arhar dal', 'moong dal', 'masoor dal',
      'chana dal', 'urad dal', 'rajma', 'kidney beans', 'chickpeas',
      'kabuli chana', 'black chana', 'green gram', 'black gram',
      'lentils', 'split lentils', 'whole lentils',
    ],

    // FOOD & DINING - SPICES
    CategoryKey('Food & Dining', 'Groceries'): [
      'turmeric', 'haldi', 'chilli powder', 'red chilli',
      'coriander powder', 'dhaniya', 'cumin', 'jeera',
      'mustard seeds', 'rai', 'fenugreek', 'methi',
      'garam masala', 'curry powder', 'biryani masala',
      'pepper', 'black pepper', 'cardamom', 'elaichi',
      'cinnamon', 'dalchini', 'cloves', 'laung',
      'bay leaf', 'tejpatta', 'star anise', 'fennel seeds', 'saunf',
    ],

    // FOOD & DINING - DAIRY
    CategoryKey('Food & Dining', 'Dairy'): [
      'milk', 'full cream milk', 'toned milk', 'double toned milk',
      'amul milk', 'mother dairy', 'nandini milk',
      'curd', 'dahi', 'yogurt', 'yoghurt',
      'paneer', 'cottage cheese', 'cheese', 'processed cheese',
      'cheese slice', 'cheese spread', 'amul cheese',
      'butter', 'amul butter', 'white butter', 'salted butter',
      'cream', 'fresh cream', 'milk cream',
      'buttermilk', 'lassi', 'flavoured milk',
    ],

    // FOOD & DINING - VEGETABLES
    CategoryKey('Food & Dining', 'Vegetables'): [
      'tomato', 'potato', 'onion', 'garlic', 'ginger',
      'capsicum', 'bell pepper', 'green chilli', 'red chilli',
      'brinjal', 'eggplant', 'baingan', 'okra', 'bhindi', 'ladyfinger',
      'cauliflower', 'gobi', 'cabbage', 'patta gobi',
      'carrot', 'gajar', 'beetroot', 'radish', 'mooli',
      'pumpkin', 'kaddu', 'bottle gourd', 'lauki', 'bitter gourd', 'karela',
      'ridge gourd', 'turai', 'snake gourd', 'cucumber', 'kheera',
      'spinach', 'palak', 'fenugreek leaves', 'methi leaves',
      'coriander', 'dhania', 'mint', 'pudina', 'curry leaves',
      'beans', 'french beans', 'green beans', 'cluster beans',
      'peas', 'green peas', 'matar', 'corn', 'sweet corn',
      'mushroom', 'baby corn', 'zucchini', 'broccoli',
    ],

    // FOOD & DINING - FRUITS
    CategoryKey('Food & Dining', 'Fruits'): [
      'apple', 'banana', 'kela', 'mango', 'aam',
      'orange', 'santara', 'grapes', 'angur', 'watermelon', 'tarbooj',
      'papaya', 'papita', 'pineapple', 'ananas', 'pomegranate', 'anar',
      'guava', 'amrud', 'sapota', 'chiku', 'chickoo',
      'mosambi', 'sweet lime', 'lemon', 'nimbu', 'lime',
      'strawberry', 'kiwi', 'dragon fruit', 'avocado',
      'coconut', 'nariyal', 'dates', 'khajur', 'dry fruits',
      'cashew', 'kaju', 'almond', 'badam', 'walnut', 'akhrot',
      'raisins', 'kishmish', 'pista', 'pistachio',
    ],

    // FOOD & DINING - BAKERY
    CategoryKey('Food & Dining', 'Bakery'): [
      'bread', 'white bread', 'brown bread', 'multigrain bread',
      'pav', 'bun', 'burger bun', 'hot dog bun',
      'cake', 'pastry', 'muffin', 'cupcake',
      'biscuit', 'cookies', 'parle g', 'marie', 'good day',
      'rusk', 'toast', 'croissant', 'donut',
    ],

    // FOOD & DINING - SNACKS
    CategoryKey('Food & Dining', 'Snacks'): [
      'chips', 'lays', 'kurkure', 'bingo', 'potato chips',
      'namkeen', 'mixture', 'bhujia', 'sev', 'chivda',
      'popcorn', 'corn flakes', 'chocos', 'muesli',
      'oats', 'quaker oats', 'instant oats',
      'noodles', 'maggi', 'yippee', 'top ramen', 'instant noodles',
      'pasta', 'macaroni', 'penne', 'fusilli',
    ],

    // FOOD & DINING - BEVERAGES
    CategoryKey('Food & Dining', 'Beverages'): [
      'tea', 'chai', 'tea powder', 'tea bags', 'green tea',
      'tata tea', 'red label', 'taj mahal tea', 'lipton',
      'coffee', 'nescafe', 'bru', 'instant coffee', 'coffee powder',
      'cold coffee', 'cappuccino', 'espresso',
      'juice', 'fruit juice', 'mango juice', 'orange juice',
      'real juice', 'tropicana', 'minute maid',
      'soft drink', 'cola', 'pepsi', 'coca cola', 'coke',
      'sprite', 'fanta', 'limca', 'thums up', '7up',
      'water', 'mineral water', 'bisleri', 'kinley', 'aquafina',
      'energy drink', 'red bull', 'monster', 'gatorade',
    ],

    // FOOD & DINING - FROZEN FOODS
    CategoryKey('Food & Dining', 'Frozen Foods'): [
      'frozen', 'ice cream', 'frozen vegetables', 'frozen peas',
      'frozen chicken', 'frozen fish', 'frozen prawns',
      'frozen paratha', 'frozen samosa', 'frozen nuggets',
    ],

    // FOOD & DINING - RESTAURANTS (Dine-in/Takeaway)
    CategoryKey('Food & Dining', 'Restaurants'): [
      'restaurant', 'dining', 'food court', 'cafe', 'cafeteria',
      'pizza', 'burger', 'sandwich', 'biryani', 'biriyani',
      'thali', 'meal', 'combo', 'lunch', 'dinner', 'breakfast',
      'dominos', 'pizza hut', 'papa johns',
      'mcdonalds', 'kfc', 'burger king', 'subway',
      'chinese', 'north indian', 'south indian', 'mughlai',
      'dosa', 'idli', 'vada', 'sambar', 'chutney',
      'chicken', 'mutton', 'fish', 'prawns', 'seafood',
      'paneer tikka', 'tandoori', 'kebab', 'tikka',
      'starbucks', 'cafe coffee day', 'ccd', 'barista',
    ],

    // FOOD & DINING - DELIVERY (Swiggy/Zomato)
    CategoryKey('Food & Dining', 'Food Delivery'): [
      'swiggy', 'zomato', 'uber eats', 'food delivery',
      'delivery charges', 'platform fee', 'packaging charges',
      'dominos delivery', 'kfc delivery', 'mcdonalds delivery',
    ],

    // SHOPPING - CLOTHING
    CategoryKey('Shopping', 'Clothing'): [
      'shirt', 't-shirt', 'tshirt', 'tee', 'polo',
      'pant', 'trousers', 'jeans', 'denim', 'chinos',
      'kurta', 'kurti', 'salwar', 'churidar', 'dupatta',
      'saree', 'sari', 'blouse', 'petticoat',
      'dress', 'gown', 'frock', 'skirt', 'lehenga',
      'jacket', 'blazer', 'coat', 'sweater', 'hoodie',
      'shorts', 'bermuda', 'track pants', 'joggers',
      'nightwear', 'pajama', 'pyjama', 'nightsuit',
      'innerwear', 'underwear', 'bra', 'panty', 'vest',
      'socks', 'handkerchief', 'scarf', 'stole', 'shawl',
    ],

    // SHOPPING - FOOTWEAR
    CategoryKey('Shopping', 'Footwear'): [
      'shoes', 'formal shoes', 'casual shoes', 'sports shoes',
      'sneakers', 'running shoes', 'nike', 'adidas', 'puma',
      'sandals', 'slippers', 'flip flops', 'chappals',
      'heels', 'high heels', 'wedges', 'flats', 'bellies',
      'boots', 'crocs', 'kolhapuri', 'mojari',
    ],

    // SHOPPING - ACCESSORIES
    CategoryKey('Shopping', 'Accessories'): [
      'belt', 'wallet', 'purse', 'handbag', 'bag',
      'backpack', 'laptop bag', 'school bag', 'suitcase', 'luggage',
      'watch', 'smartwatch', 'wristwatch', 'fitness band',
      'sunglasses', 'spectacles', 'goggles', 'eyewear',
      'jewellery', 'jewelry', 'earrings', 'necklace', 'ring',
      'bracelet', 'chain', 'pendant', 'bangle', 'anklet',
      'tie', 'bow tie', 'cufflinks', 'brooch',
      'cap', 'hat', 'helmet', 'umbrella',
    ],

    // SHOPPING - ELECTRONICS
    CategoryKey('Shopping', 'Electronics'): [
      'mobile', 'smartphone', 'phone', 'iphone', 'samsung',
      'oneplus', 'redmi', 'realme', 'oppo', 'vivo',
      'laptop', 'notebook', 'macbook', 'dell', 'hp', 'lenovo',
      'tablet', 'ipad', 'tab', 'kindle', 'e-reader',
      'desktop', 'computer', 'pc', 'monitor', 'screen',
      'keyboard', 'mouse', 'webcam', 'speaker', 'headphone',
      'earphone', 'earbuds', 'airpods', 'bluetooth speaker',
      'charger', 'mobile charger', 'laptop charger', 'power bank',
      'cable', 'usb cable', 'charging cable', 'data cable',
      'adapter', 'converter', 'extension cord', 'power strip',
      'hard disk', 'ssd', 'pen drive', 'usb drive', 'memory card',
      'camera', 'dslr', 'lens', 'tripod', 'gimbal',
      'television', 'tv', 'smart tv', 'led tv', 'oled tv',
      'sony', 'lg', 'samsung tv', 'mi tv', 'one plus tv',
      'ac', 'air conditioner', 'cooler', 'air cooler', 'fan',
      'ceiling fan', 'table fan', 'exhaust fan',
      'refrigerator', 'fridge', 'double door fridge',
      'washing machine', 'front load', 'top load', 'semi automatic',
      'microwave', 'oven', 'otg', 'toaster', 'mixer', 'grinder',
      'induction', 'gas stove', 'water purifier', 'ro', 'water filter',
      'geyser', 'water heater', 'iron', 'steam iron', 'vacuum cleaner',
    ],

    // SHOPPING - MOBILE ACCESSORIES
    CategoryKey('Shopping', 'Mobile Accessories'): [
      'mobile cover', 'phone case', 'back cover', 'flip cover',
      'screen protector', 'tempered glass', 'screen guard',
      'mobile charger', 'fast charger', 'wireless charger',
      'charging cable', 'usb cable', 'type c cable', 'lightning cable',
      'earphones', 'wired earphones', 'bluetooth earphones',
      'phone holder', 'car mount', 'pop socket', 'ring holder',
      'selfie stick', 'tripod stand', 'otg adapter',
    ],

    // SHOPPING - BOOKS & STATIONERY
    CategoryKey('Shopping', 'Books & Stationery'): [
      'book', 'novel', 'textbook', 'notebook', 'diary',
      'pen', 'pencil', 'eraser', 'sharpener', 'scale', 'ruler',
      'marker', 'highlighter', 'sketch pen', 'crayon',
      'paper', 'a4 paper', 'chart paper', 'file', 'folder',
      'stapler', 'staples', 'pin', 'clip', 'paper clip',
      'glue', 'fevicol', 'tape', 'cello tape', 'scissors',
      'calculator', 'compass', 'protractor', 'geometry box',
    ],

    // SHOPPING - HOME & KITCHEN
    CategoryKey('Shopping', 'Home & Kitchen'): [
      'utensils', 'plate', 'bowl', 'spoon', 'fork', 'knife',
      'glass', 'cup', 'mug', 'tumbler', 'bottle', 'water bottle',
      'tiffin', 'lunch box', 'container', 'storage box',
      'kadai', 'wok', 'pan', 'tawa', 'frying pan', 'pressure cooker',
      'cooker', 'steel utensils', 'non stick', 'cookware',
      'bedsheet', 'bed cover', 'pillow', 'pillow cover',
      'blanket', 'quilt', 'dohar', 'comforter', 'mattress',
      'curtain', 'table cloth', 'towel', 'bath towel', 'hand towel',
      'bucket', 'mug', 'drum', 'storage drum', 'dustbin',
      'broom', 'jhadu', 'pocha', 'mop', 'wiper', 'duster',
      'hanger', 'clothes stand', 'ironing board',
    ],

    // SHOPPING - PERSONAL CARE
    CategoryKey('Shopping', 'Personal Care'): [
      'soap', 'bathing soap', 'handwash', 'hand soap',
      'dettol', 'lifebuoy', 'lux', 'dove', 'pears',
      'shampoo', 'conditioner', 'hair oil', 'hair gel', 'hair cream',
      'head & shoulders', 'clinic plus', 'pantene', 'sunsilk',
      'toothpaste', 'toothbrush', 'mouthwash', 'dental floss',
      'colgate', 'pepsodent', 'close up', 'sensodyne',
      'facewash', 'face cream', 'moisturizer', 'lotion', 'body lotion',
      'fairness cream', 'face pack', 'scrub', 'face wash',
      'sunscreen', 'sun cream', 'sunblock', 'spf cream',
      'talcum powder', 'powder', 'baby powder', 'prickly heat powder',
      'deodorant', 'deo', 'perfume', 'body spray', 'axe', 'fogg',
      'razor', 'shaving cream', 'after shave', 'beard oil',
      'trimmer', 'shaver', 'epilator', 'hair dryer', 'straightener',
      'nail cutter', 'nail polish', 'makeup', 'lipstick', 'kajal',
      'eyeliner', 'mascara', 'foundation', 'compact', 'sindoor',
      'comb', 'brush', 'hair brush', 'hair band', 'hair clip',
      'tissue', 'tissue paper', 'napkin', 'wet wipes', 'baby wipes',
      'cotton', 'cotton buds', 'ear buds', 'sanitary pads', 'tampons',
    ],

    // HEALTHCARE - MEDICINES
    CategoryKey('Healthcare', 'Medicines'): [
      'medicine', 'tablet', 'capsule', 'syrup', 'suspension',
      'injection', 'ointment', 'cream', 'gel', 'drops',
      'paracetamol', 'dolo', 'crocin', 'fever medicine',
      'cough syrup', 'cold medicine', 'antibiotic',
      'pain killer', 'pain relief', 'headache medicine',
      'antacid', 'digestion', 'stomach medicine',
      'vitamin', 'multivitamin', 'supplement', 'calcium',
      'vitamin d', 'vitamin c', 'omega 3', 'protein powder',
      'inhaler', 'nebulizer', 'vaporizer', 'steam',
      'bandage', 'gauze', 'cotton', 'dressing', 'plaster',
      'antiseptic', 'dettol', 'savlon', 'betadine',
      'thermometer', 'bp machine', 'glucometer', 'glucose meter',
      'mask', 'surgical mask', 'n95 mask', 'sanitizer', 'hand sanitizer',
    ],

    // HEALTHCARE - PHARMACY
    CategoryKey('Healthcare', 'Pharmacy'): [
      'apollo pharmacy', 'medplus', 'netmeds', '1mg', 'pharmeasy',
      'pharmacy', 'medical store', 'chemist',
    ],

    // TRANSPORTATION - FUEL
    CategoryKey('Transportation', 'Fuel'): [
      'petrol', 'diesel', 'fuel', 'cng', 'gas',
      'indian oil', 'bharat petroleum', 'bpcl', 'hp', 'hindustan petroleum',
      'shell', 'reliance petroleum', 'essar',
    ],

    // TRANSPORTATION - CAB/TAXI
    CategoryKey('Transportation', 'Cab/Taxi'): [
      'ola', 'uber', 'rapido', 'auto', 'cab', 'taxi',
      'ride', 'bike ride', 'auto rickshaw', 'rickshaw',
    ],

    // TRANSPORTATION - PUBLIC TRANSPORT
    CategoryKey('Transportation', 'Public Transport'): [
      'metro', 'subway', 'local train', 'bus', 'bmtc', 'best',
      'metro card', 'bus pass', 'monthly pass', 'smart card',
      'ticket', 'railway ticket', 'train ticket',
    ],

    // TRANSPORTATION - PARKING
    CategoryKey('Transportation', 'Parking'): [
      'parking', 'parking fee', 'valet', 'toll', 'toll tax',
    ],

    // BILLS & UTILITIES - ELECTRICITY
    CategoryKey('Bills & Utilities', 'Electricity'): [
      'electricity', 'electricity bill', 'power bill', 'eb bill',
      'bescom', 'msedcl', 'tata power', 'adani electricity',
    ],

    // BILLS & UTILITIES - WATER
    CategoryKey('Bills & Utilities', 'Water'): [
      'water bill', 'water tax', 'bwssb', 'water supply',
    ],

    // BILLS & UTILITIES - GAS
    CategoryKey('Bills & Utilities', 'Gas'): [
      'gas', 'lpg', 'cylinder', 'gas cylinder', 'cooking gas',
      'indane', 'hp gas', 'bharat gas',
    ],

    // BILLS & UTILITIES - INTERNET/MOBILE
    CategoryKey('Bills & Utilities', 'Internet/Mobile'): [
      'internet', 'broadband', 'wifi', 'fiber', 'internet bill',
      'airtel', 'jio', 'vodafone', 'vi', 'bsnl', 'idea',
      'mobile recharge', 'recharge', 'data pack', 'plan',
      'airtel xtreme', 'jio fiber', 'act fibernet', 'hathway',
    ],

    // BILLS & UTILITIES - DTH/TV
    CategoryKey('Bills & Utilities', 'Cable/DTH'): [
      'dth', 'dish tv', 'tata sky', 'airtel digital tv', 'sun direct',
      'cable', 'cable tv', 'tv subscription',
    ],

    // ENTERTAINMENT - MOVIES
    CategoryKey('Entertainment', 'Movies'): [
      'movie', 'cinema', 'ticket', 'movie ticket',
      'pvr', 'inox', 'cinepolis', 'carnival', 'gopalan',
      'bookmyshow', 'paytm movies',
    ],

    // ENTERTAINMENT - STREAMING
    CategoryKey('Entertainment', 'Subscriptions'): [
      'netflix', 'amazon prime', 'prime video', 'disney+', 'hotstar',
      'disney+ hotstar', 'zee5', 'sonyliv', 'voot', 'mx player',
      'youtube premium', 'spotify', 'apple music', 'gaana', 'wynk',
      'subscription', 'monthly subscription', 'annual subscription',
    ],

    // EDUCATION - FEES
    CategoryKey('Education', 'Tuition'): [
      'school fee', 'tuition fee', 'college fee', 'coaching',
      'admission fee', 'exam fee', 'course fee',
      'byju', 'unacademy', 'vedantu', 'online class',
    ],

    // EDUCATION - BOOKS & SUPPLIES
    CategoryKey('Education', 'Books'): [
      'textbook', 'reference book', 'study material',
      'course book', 'workbook', 'guide',
    ],

    // FITNESS - GYM
    CategoryKey('Health & Fitness', 'Gym'): [
      'gym', 'gym membership', 'fitness center', 'gymnasium',
      'cult fit', 'gold gym', 'anytime fitness', 'fitness first',
      'personal training', 'trainer', 'yoga', 'zumba', 'aerobics',
    ],

    // GIFTS & DONATIONS
    CategoryKey('Others', 'Gifts'): [
      'gift', 'present', 'birthday gift', 'anniversary gift',
      'donation', 'charity', 'temple', 'church', 'mosque', 'gurudwara',
      'dakshina', 'offering',
    ],

    // INSURANCE
    CategoryKey('Bills & Utilities', 'Insurance'): [
      'insurance', 'life insurance', 'health insurance', 'car insurance',
      'bike insurance', 'vehicle insurance', 'term insurance',
      'lic', 'policy premium', 'premium',
    ],

    // REPAIRS & MAINTENANCE
    CategoryKey('Home & Maintenance', 'Repairs'): [
      'repair', 'service', 'maintenance', 'plumber', 'electrician',
      'carpenter', 'painter', 'ac service', 'vehicle service',
      'bike service', 'car wash', 'cleaning', 'pest control',
    ],
  };

  // ============================================================================
  // MERCHANT DATABASE (Store/Restaurant Recognition)
  // ============================================================================

  final Map<CategoryKey, List<String>> _merchantDatabase = {
    // RETAIL STORES
    CategoryKey('Shopping', 'Retail'): [
      'dmart', 'd mart', 'reliance fresh', 'reliance smart', 'smart bazaar',
      'big bazaar', 'more', 'spencer', 'hypercity', 'star bazaar',
      'vishal mega mart', 'v mart', 'easy day', 'margin free',
    ],

    // ONLINE SHOPPING
    CategoryKey('Shopping', 'Online'): [
      'amazon', 'flipkart', 'myntra', 'ajio', 'meesho',
      'jiomart', 'blinkit', 'grofers', 'zepto', 'dunzo', 'big basket',
      'swiggy instamart', 'amazon fresh', 'flipkart grocery',
    ],

    // FAST FOOD
    CategoryKey('Food & Dining', 'Fast Food'): [
      'mcdonalds', 'mcd', 'kfc', 'burger king', 'subway',
      'dominos', 'pizza hut', 'papa johns', 'taco bell',
      'dunkin donuts', 'baskin robbins', 'kwality walls',
    ],

    // FOOD DELIVERY
    CategoryKey('Food & Dining', 'Food Delivery'): [
      'swiggy', 'zomato', 'uber eats', 'box8', 'faasos',
    ],

    // CAFES
    CategoryKey('Food & Dining', 'Cafes'): [
      'starbucks', 'cafe coffee day', 'ccd', 'barista',
      'costa coffee', 'blue tokai', 'third wave coffee',
    ],

    // FUEL STATIONS
    CategoryKey('Transportation', 'Fuel'): [
      'indian oil', 'hp', 'bharat petroleum', 'bpcl',
      'shell', 'reliance petroleum', 'essar oil',
    ],

    // PHARMACIES
    CategoryKey('Healthcare', 'Pharmacy'): [
      'apollo pharmacy', 'apollo', 'medplus', 'wellness forever',
      'netmeds', '1mg', 'pharmeasy', 'medical store',
    ],

    // ELECTRONICS STORES
    CategoryKey('Shopping', 'Electronics'): [
      'croma', 'reliance digital', 'vijay sales', 'girias',
      'poorvika', 'samsung store', 'mi store', 'apple store',
    ],
  };
}

// ============================================================================
// MODELS
// ============================================================================

class CategoryKey {
  final String category;
  final String subcategory;

  CategoryKey(this.category, this.subcategory);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryKey &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          subcategory == other.subcategory;

  @override
  int get hashCode => category.hashCode ^ subcategory.hashCode;
}

class CategoryMatch {
  final String category;
  final String subcategory;
  final double confidence;
  final String matchedKeyword;

  CategoryMatch({
    required this.category,
    required this.subcategory,
    required this.confidence,
    required this.matchedKeyword,
  });
}

class ItemSuggestion {
  final String itemName;
  final String category;
  final String subcategory;
  final double similarity;

  ItemSuggestion({
    required this.itemName,
    required this.category,
    required this.subcategory,
    required this.similarity,
  });

  String get emoji {
    // Return emoji based on category
    switch (category) {
      case 'Food & Dining':
        return '🍽️';
      case 'Shopping':
        return '🛍️';
      case 'Transportation':
        return '🚗';
      case 'Healthcare':
        return '💊';
      case 'Entertainment':
        return '🎬';
      case 'Bills & Utilities':
        return '💡';
      case 'Education':
        return '📚';
      case 'Health & Fitness':
        return '💪';
      default:
        return '📦';
    }
  }
}

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<dynamic, dynamic> json) =>
      Category(id: json['id'] as String, name: json['name'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Product {
  final String title;
  final Category category;
  final double price;
  final String image;
  final String shortDesc;
  final Map<String, String> specs;
  final Ratings ratings;
  final int discountPercent;
  final Map<String, Review> reviews;

  Product({
    required this.title,
    required this.category,
    required this.price,
    required this.image,
    required this.shortDesc,
    required this.specs,
    required this.ratings,
    required this.discountPercent,
    required this.reviews,
  });

  factory Product.fromJson(Map<dynamic, dynamic> json) => Product(
        title: json['title'] as String,
        category: json['category'] != null
            ? Category.fromJson(json['category'] as Map<dynamic, dynamic>)
            : Category(id: '', name: ''),
        price: (json['price'] is int)
            ? (json['price'] as int).toDouble()
            : (json['price'] as double? ?? 0.0),
        image: json['image'] as String,
        shortDesc: json['shortDesc'] as String,
        specs: Map<String, String>.from(json['specs'] as Map),
        ratings: json['ratings'] != null
            ? Ratings.fromJson(json['ratings'] as Map<dynamic, dynamic>)
            : Ratings(average: 0, count: 0),
        discountPercent: json['discountPercent'] as int? ?? 0,
        reviews: (json['reviews'] as Map<dynamic, dynamic>?)?.map(
              (key, value) => MapEntry(
                key.toString(),
                Review.fromJson(value as Map<dynamic, dynamic>),
              ),
            ) ??
            {},
      );

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'title': title,
        'category': category.toJson(),
        'price': price,
        'image': image,
        'shortDesc': shortDesc,
        'specs': specs,
        'ratings': ratings.toJson(),
        'discountPercent': discountPercent,
        'reviews': reviews.map((key, value) => MapEntry(key, value.toJson())),
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'title': title,
        'category': category.toJson(),
        'price': price,
        'image': image,
        'shortDesc': shortDesc,
        'specs': specs,
        'ratings': ratings.toMap(),
        'discountPercent': discountPercent,
        'reviews': reviews.map((key, value) => MapEntry(key, value.toMap())),
      };
}

class Ratings {
  final double average;
  final int count;

  Ratings({required this.average, required this.count});

  factory Ratings.fromJson(Map<dynamic, dynamic>? json) => Ratings(
        average: (json?['average'] is int)
            ? (json?['average'] as int).toDouble()
            : (json?['average'] as double? ?? 0.0),
        count: json?['count'] as int? ?? 0,
      );

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'average': average,
        'count': count,
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'average': average,
        'count': count,
      };
}

class Review {
  final String userId;
  final int rating;
  final String comment;
  final int likes;
  final int createdAt;

  Review({
    required this.userId,
    required this.rating,
    required this.comment,
    required this.likes,
    required this.createdAt,
  });

  factory Review.fromJson(Map<dynamic, dynamic> json) => Review(
        userId: json['userId'] as String? ?? '',
        rating: json['rating'] as int? ?? 0,
        comment: json['comment'] as String? ?? '',
        likes: json['likes'] as int? ?? 0,
        createdAt: json['createdAt'] as int? ?? 0,
      );

  Map<dynamic, dynamic> toJson() => <dynamic, dynamic>{
        'userId': userId,
        'rating': rating,
        'comment': comment,
        'likes': likes,
        'createdAt': createdAt,
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'userId': userId,
        'rating': rating,
        'comment': comment,
        'likes': likes,
        'createdAt': createdAt,
      };
}

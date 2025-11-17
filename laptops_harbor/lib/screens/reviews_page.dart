import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:laptops_harbor/models/review.dart';
import 'package:laptops_harbor/style/theme.dart';

class ReviewsPage extends StatefulWidget {
  final String productId;

  const ReviewsPage({super.key, required this.productId});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  double rating = 0;
  String comment = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cyan,
        title: const Text("Reviews"),
      ),
      body: Column(
        children: [
          // Add Review Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text("Add Your Review", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: black)),
                const SizedBox(height: 10),
                RatingBar.builder(
                  initialRating: rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (value) => setState(() => rating = value),
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(labelText: "Comment", labelStyle: TextStyle(color: grey)),
                  onChanged: (value) => comment = value,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _submitReview(),
                  style: ElevatedButton.styleFrom(backgroundColor: cyan),
                  child: const Text("Submit Review", style: TextStyle(color: white)),
                ),
              ],
            ),
          ),
          const Divider(),
          // Reviews List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Products')
                  .doc(widget.productId)
                  .collection('reviews')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No reviews yet.", style: TextStyle(color: grey)));
                }

                final reviews = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final reviewData = reviews[index].data() as Map<String, dynamic>;
                    final review = Review.fromDocument(reviews[index]);

                    return Card(
                      margin: const EdgeInsets.all(8),
                      color: lightGrey,
                      child: ListTile(
                        title: Row(
                          children: [
                            Text(reviewData['userName'] ?? 'Anonymous', style: const TextStyle(color: black)),
                            const SizedBox(width: 10),
                            RatingBarIndicator(
                              rating: review.rating,
                              itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                              itemCount: 5,
                              itemSize: 20.0,
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(review.comment, style: const TextStyle(color: black)),
                            Text(review.createdAt.toDate().toString().substring(0, 19), style: const TextStyle(fontSize: 12, color: grey)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _submitReview() async {
    if (rating == 0 || comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide rating and comment.")));
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();
      final userName = userDoc.data()?['Name'] ?? 'Anonymous';

      final reviewRef = FirebaseFirestore.instance
          .collection('Products')
          .doc(widget.productId)
          .collection('reviews')
          .doc();

      final review = Review(
        id: reviewRef.id,
        userId: userId,
        productId: widget.productId,
        rating: rating,
        comment: comment,
        createdAt: Timestamp.now(),
      );

      await reviewRef.set(review.toMap());

      setState(() {
        rating = 0;
        comment = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review submitted!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}

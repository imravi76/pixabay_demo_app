import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Gallery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ImageGallery(),
    );
  }
}

class ImageGallery extends StatefulWidget {
  const ImageGallery({super.key});

  @override
  _ImageGalleryState createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  final List<dynamic> _images = [];
  bool _loading = true;
  int _page = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchImages();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> fetchImages() async {
    final queryParams = {
      'key': '11990318-dcf17d26f79864dd1e5099fba',
      'q': 'nature',
      'image_type': 'photo',
      'page': _page.toString(),
    };
    final uri = Uri.https('pixabay.com', '/api/', queryParams);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      setState(() {
        _images.addAll(json.decode(response.body)['hits']);
        _loading = false;
        _page++;
      });
    } else {
      throw Exception('Failed to load images');
    }
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      fetchImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Gallery'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : GridView.builder(
              controller: _scrollController,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    calculateCrossAxisCount(MediaQuery.of(context).size.width),
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _images.length,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImage(
                          imageUrl: _images[index]['largeImageURL'],
                          likes: _images[index]['likes'],
                          views: _images[index]['views'],
                          heroTag: 'image$index',
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'image$index',
                    child: GridTile(
                      footer: GridTileBar(
                        backgroundColor: Colors.black45,
                        title: Text('Likes: ${_images[index]['likes']}'),
                        subtitle: Text('Views: ${_images[index]['views']}'),
                      ),
                      child: Image.network(
                        _images[index]['previewURL'],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  int calculateCrossAxisCount(double screenWidth) {
    return (screenWidth / 150).round();
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  final int likes;
  final int views;
  final String heroTag;

  const FullScreenImage(
      {super.key,
      required this.imageUrl,
      required this.likes,
      required this.views,
      required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Hero(
              tag: heroTag,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  } else {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        child,
                        CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          backgroundColor: Colors.white,
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

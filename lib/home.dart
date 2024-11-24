import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'agenda.dart';
import 'info.dart';
import 'galery.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _bannerImages = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentBannerIndex = 0;
  final PageController _pageController = PageController();
  List<dynamic> _agendaData = [];
  List<dynamic> _infoData = [];
  List<dynamic> _galleryData = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    fetchAllData();
    _animationController.forward();
    
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) autoScrollBanner();
    });
  }

  Future<void> fetchAllData() async {
    try {
      await Future.wait([
        fetchBannerImages(),
        fetchAgendaData(),
        fetchInfoData(),
        fetchGalleryData(),
      ]);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching all data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchAgendaData() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/categories/7'),
        headers: {'Accept': 'application/json'},
      );

      print('Agenda response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          _agendaData = (jsonResponse['posts'] as List? ?? []).take(3).toList();
        });
      }
    } catch (e) {
      print('Error fetching agenda: $e');
    }
  }

  Future<void> fetchInfoData() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/categories/1'),
        headers: {'Accept': 'application/json'},
      );

      print('Info response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          _infoData = (jsonResponse['posts'] as List? ?? []).take(3).toList();
        });
      }
    } catch (e) {
      print('Error fetching info: $e');
    }
  }

  Future<void> fetchGalleryData() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:8000/api/images'));

      print('Gallery response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          _galleryData = (jsonResponse as List? ?? []).take(3).toList();
        });
      }
    } catch (e) {
      print('Error fetching gallery: $e');
    }
  }

  void autoScrollBanner() {
    if (_bannerImages.isEmpty) return;
    Future.delayed(Duration(seconds: 3), () {
      if (!mounted) return;
      int nextPage = _currentBannerIndex + 1;
      if (nextPage >= _bannerImages.length) nextPage = 0;
      
      _pageController.animateToPage(
        nextPage,
        duration: Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
      
      autoScrollBanner();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> fetchBannerImages() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:8000/api/images'));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          _bannerImages = jsonResponse;
          _isLoading = false;
        });
      } else {
        print('Error: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching banner images: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Banner Section
          Container(
            height: 250,
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentBannerIndex = index;
                          });
                        },
                        itemCount: _bannerImages.length,
                        itemBuilder: (context, index) {
                          final imageUrl = 'http://10.0.2.2:8000/images/${_bannerImages[index]['file']}';
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 5),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: Icon(Icons.error_outline, size: 50),
                                      );
                                    },
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.7),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 20,
                                    left: 20,
                                    right: 20,
                                    child: Text(
                                      _bannerImages[index]['title'] ?? '',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      // Indicator dots
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _bannerImages.length,
                            (index) => Container(
                              width: 8,
                              height: 8,
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentBannerIndex == index
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // Section Agenda dengan data dari API agenda
          _buildSection(
            title: 'Agenda Terbaru',
            items: _agendaData.map((item) {
              return _buildItemCard(
                title: item['title'] ?? 'Untitled',
                content: item['content'] ?? '',
                date: _formatDate(item['created_at']),
              );
            }).toList(),
            onSeeMore: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AgendaScreen(),
              ));
            },
          ),

          // Section Informasi dengan data dari API informasi
          _buildSection(
            title: 'Informasi Terbaru',
            items: _infoData.map((item) {
              return _buildItemCard(
                title: item['title'] ?? 'Untitled',
                content: item['content'] ?? '',
                date: _formatDate(item['created_at']),
              );
            }).toList(),
            onSeeMore: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => InfoScreen(),
              ));
            },
          ),

          // Section Galeri dengan data dari API galeri
          _buildSection(
            title: 'Galeri Terbaru',
            items: _galleryData.map((item) {
              return _buildItemCard(
                imageUrl: 'http://10.0.2.2:8000/images/${item['file']}',
                title: item['title'] ?? 'Untitled',
                isGallery: true,
              );
            }).toList(),
            onSeeMore: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => GaleryScreen(),
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> items,
    required VoidCallback onSeeMore,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2A5E),
                ),
              ),
              TextButton(
                onPressed: onSeeMore,
                child: Text(
                  'Selengkapnya',
                  style: TextStyle(
                    color: Color(0xFF3A4B8C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard({
    String? imageUrl,
    required String title,
    String? content,
    String? date,
    bool isGallery = false,
  }) {
    return Container(
      width: 150,
      margin: EdgeInsets.only(right: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isGallery && imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(
                  imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      color: Colors.grey[300],
                      child: Icon(Icons.error_outline),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (content != null) ...[
                    SizedBox(height: 4),
                    Text(
                      content,
                      style: TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (date != null) ...[
                    SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}-${date.month}-${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

import 'package:flutter/material.dart';
import '../../../../../../config/api_config.dart';
import '../../../../../../core/networking/api_client.dart';
import '../../../../../../core/storage/token_storage.dart';
import '../../../data/syllabus_api.dart';
import '../../../data/syllabus_repository.dart';
import '../../home/syllabus_screen.dart'; // Import for Explore More
import '../../home/syllabus_content_screen.dart'; // Import for Content Viewer
import '../my_courses_screen.dart'; // Import for constants

class PurchasedSyllabusTab extends StatefulWidget {
  const PurchasedSyllabusTab({super.key});

  @override
  State<PurchasedSyllabusTab> createState() => _PurchasedSyllabusTabState();
}

class _PurchasedSyllabusTabState extends State<PurchasedSyllabusTab> with AutomaticKeepAliveClientMixin {
  late final SyllabusRepository _syllabusRepository;

  bool _isLoading = true;
  String? _error;
  List<dynamic> _syllabuses = [];
  List<dynamic> _recommendedSyllabuses = [];
  bool _showRecommendedSyllabuses = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(baseUrl: ApiConfig.baseUrl, tokenStorage: TokenStorage());
    _syllabusRepository = SyllabusRepository(SyllabusApi(apiClient));
    _fetchSyllabuses();
  }

  Future<void> _fetchSyllabuses() async {
    if (_syllabuses.isNotEmpty && !_showRecommendedSyllabuses) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final purchasedSyllabuses = await _syllabusRepository.getPurchasedSyllabus();

      if (purchasedSyllabuses.isEmpty) {
        final allSyllabuses = await _syllabusRepository.getSyllabus();
        if (mounted) {
          setState(() {
            _syllabuses = [];
            _recommendedSyllabuses = allSyllabuses;
            _showRecommendedSyllabuses = true;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _syllabuses = purchasedSyllabuses;
            _showRecommendedSyllabuses = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        // Fallback to recommendations on error
        try {
          final allSyllabuses = await _syllabusRepository.getSyllabus();
          setState(() {
            _syllabuses = [];
            _recommendedSyllabuses = allSyllabuses;
            _showRecommendedSyllabuses = true;
            _isLoading = false;
          });
        } catch (_) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _syllabuses = [];
      _showRecommendedSyllabuses = false;
      _isLoading = true;
    });
    await _fetchSyllabuses();
  }

  Widget _buildSyllabusCard(dynamic syllabus, {bool isRecommended = false}) {
    final title = syllabus['title'] ?? 'Untitled Syllabus';
    final thumbnailUrl = syllabus['thumbnailUrl'];
    final rawId = syllabus['syllabusId'] ?? syllabus['id'];
    final int? syllabusId = rawId is int ? rawId : (rawId is String ? int.tryParse(rawId) : null);

    if (syllabusId == null) {
      print('⚠️ Warning: Syllabus ID is null for syllabus: $title');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadius),
          onTap: syllabusId == null
              ? null
              : () {
                  if (isRecommended) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SyllabusScreen()));
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SyllabusContentScreen(syllabusId: syllabusId)),
                    );
                  }
                },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(color: Colors.indigo.shade50),
                        child: (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                            ? Image.network(thumbnailUrl, fit: BoxFit.cover)
                            : Icon(Icons.school_rounded, color: Colors.indigo.shade300, size: 30),
                      ),
                      if (isRecommended)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.star, color: Colors.amber, size: 10),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          'Syllabus',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextPrimary),
                      ),
                      const SizedBox(height: 6),
                      if (!isRecommended)
                        Row(
                          children: const [
                            Icon(Icons.check_circle, size: 14, color: Colors.green),
                            SizedBox(width: 4),
                            Text('Purchased', style: TextStyle(fontSize: 12, color: Colors.green)),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }

    return RefreshIndicator(
      color: kPrimaryColor,
      onRefresh: _refreshData,
      child: _showRecommendedSyllabuses
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.school_outlined, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No Purchased Syllabus',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kTextPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Explore our collection of syllabus items.",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 18, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Recommended Syllabus',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextPrimary),
                        ),
                      ],
                    ),
                  ),
                  ..._recommendedSyllabuses.take(3).map((s) => _buildSyllabusCard(s, isRecommended: true)),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SyllabusScreen()));
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: kPrimaryColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Explore More Syllabus',
                          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 16),
              itemCount: _syllabuses.length,
              itemBuilder: (context, i) => _buildSyllabusCard(_syllabuses[i], isRecommended: false),
            ),
    );
  }
}

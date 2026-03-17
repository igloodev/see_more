import 'package:flutter/material.dart';
import 'package:see_more/see_more.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'See More Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ExamplePage(),
    );
  }
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  final String _longText =
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod "
      "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, "
      "quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. "
      "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu "
      "fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in "
      "culpa qui officia deserunt mollit anim id est laborum.";

  final String _shortText = "This is a short text that won't be trimmed.";

  int _expandCount = 0;
  int _collapseCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('See More Widget Examples'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Basic Character Trimming
            _buildSection(
              title: '1. Basic (Character Trimming)',
              child: SeeMoreWidget(
                _longText,
                maxCharacters: 100,
              ),
            ),

            // 2. Line-based Trimming
            _buildSection(
              title: '2. Line-based Trimming (3 lines)',
              child: SeeMoreWidget(
                _longText,
                trimMode: TrimMode.line,
                maxLines: 3,
              ),
            ),

            // 3. With Fade Effect
            _buildSection(
              title: '3. With Fade Effect',
              backgroundColor: Colors.white,
              child: SeeMoreWidget(
                _longText,
                trimMode: TrimMode.line,
                maxLines: 3,
                showFadeEffect: true,
                fadeHeight: 50,
                fadeColor: Colors.white,
              ),
            ),

            // 4. Custom Styling
            _buildSection(
              title: '4. Custom Styling',
              child: SeeMoreWidget(
                _longText,
                maxCharacters: 120,
                textStyle: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
                expandText: 'Read More',
                expandTextStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                collapseText: 'Read Less',
                collapseTextStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ),

            // 5. With Callbacks
            _buildSection(
              title: '5. With Callbacks (Expand: $_expandCount, Collapse: $_collapseCount)',
              child: SeeMoreWidget(
                _longText,
                maxCharacters: 100,
                onExpand: () {
                  setState(() => _expandCount++);
                },
                onCollapse: () {
                  setState(() => _collapseCount++);
                },
              ),
            ),

            // 6. Initially Expanded
            _buildSection(
              title: '6. Initially Expanded',
              child: SeeMoreWidget(
                _longText,
                maxCharacters: 100,
                initiallyExpanded: true,
              ),
            ),

            // 7. Custom Ellipsis
            _buildSection(
              title: '7. Custom Ellipsis',
              child: SeeMoreWidget(
                _longText,
                maxCharacters: 100,
                ellipsis: ' >>>',
              ),
            ),

            // 8. Center Aligned
            _buildSection(
              title: '8. Center Aligned',
              child: SeeMoreWidget(
                _longText,
                maxCharacters: 100,
                textAlign: TextAlign.center,
              ),
            ),

            // 9. Fade Effect with Custom Color
            _buildSection(
              title: '9. Fade on Dark Background',
              backgroundColor: Colors.grey.shade900,
              child: SeeMoreWidget(
                _longText,
                trimMode: TrimMode.line,
                maxLines: 2,
                showFadeEffect: true,
                fadeHeight: 60,
                fadeColor: Colors.grey.shade900,
                textStyle: const TextStyle(color: Colors.white),
                expandTextStyle: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
                collapseTextStyle: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // 10. Short Text (No trimming)
            _buildSection(
              title: '10. Short Text (No trimming needed)',
              child: SeeMoreWidget(
                _shortText,
                maxCharacters: 200,
              ),
            ),

            // 11. Custom Animation
            _buildSection(
              title: '11. Custom Animation (Slow)',
              child: SeeMoreWidget(
                _longText,
                maxCharacters: 100,
                animationDuration: const Duration(milliseconds: 800),
                animationCurve: Curves.elasticOut,
              ),
            ),

            // 12. Fade with Line Mode (2 lines)
            _buildSection(
              title: '12. Fade Effect (2 lines)',
              backgroundColor: const Color(0xFFF5F5F5),
              child: SeeMoreWidget(
                _longText,
                trimMode: TrimMode.line,
                maxLines: 2,
                showFadeEffect: true,
                fadeColor: const Color(0xFFF5F5F5),
              ),
            ),

            // 13. No Word Boundary Trim
            _buildSection(
              title: '13. Without Word Boundary (cuts mid-word)',
              child: SeeMoreWidget(
                _longText,
                maxCharacters: 50,
                trimAtWordBoundary: false,
              ),
            ),

            // 14. Social Media Style
            _buildSection(
              title: '14. Social Media Style',
              backgroundColor: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child: Text('JD', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'John Doe',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '2 hours ago',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SeeMoreWidget(
                    _longText,
                    trimMode: TrimMode.line,
                    maxLines: 3,
                    showFadeEffect: true,
                    fadeColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 15, height: 1.4),
                    expandText: 'more',
                    expandTextStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    collapseText: 'less',
                    collapseTextStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    Color? backgroundColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

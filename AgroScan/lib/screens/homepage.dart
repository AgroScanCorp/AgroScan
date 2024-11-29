import 'dart:io';

import 'dart:ui' as ui;
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../services/api_service.dart';
import 'package:gpt_vision_leaf_detect/constants/languages.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final apiService = ApiService();
  File? _selectedImage;
  String diseaseName = '';
  String diseasePrecautions = '';
  bool detecting = false;
  bool precautionLoading = false;
  String selectedLanguage = 'English';

  // Animation controller for the moving neon lights
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    // Create the moving animation for the gradient's stops
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile =
        await ImagePicker().pickImage(source: source, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  detectDisease() async {
    setState(() {
      detecting = true;
    });
    try {
      diseaseName =
          await apiService.sendImageToGPT4Vision(image: _selectedImage!);
    } catch (error) {
      _showErrorSnackBar(error);
    } finally {
      setState(() {
        detecting = false;
      });
    }
  }

  showPrecautions() async {
    setState(() {
      precautionLoading = true;
    });
    try {
      if (diseasePrecautions == '') {
        diseasePrecautions =
            await apiService.sendMessageGPT(diseaseName: diseaseName);
      }
      _showSuccessDialog(diseaseName, diseasePrecautions);
    } catch (error) {
      _showErrorSnackBar(error);
    } finally {
      setState(() {
        precautionLoading = false;
      });
    }
  }

  void _showErrorSnackBar(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error.toString()),
      backgroundColor: Colors.red,
    ));
  }

  void _showSuccessDialog(String title, String content) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.rightSlide,
      title: title,
      desc: content,
      btnOkText: 'Got it',
      btnOkColor: Colors.black,
      btnOkOnPress: () {},
    ).show();
  }

  Widget _buildLanguageButton() {
    return Container(
      padding: const EdgeInsets.only(right: 20, top: 20),
      child: PopupMenuButton<String>(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: Colors.black.withOpacity(0.8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: Colors.white.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedLanguage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_drop_down,
                color: Colors.white,
              ),
            ],
          ),
        ),
        onSelected: (String value) {
          setState(() {
            selectedLanguage = value;
          });
          // Get the language code from the languages map
          final locale = languages[value];
          if (locale != null) {
            // Update the app's locale using MaterialApp's locale
            Localizations.override(
              context: context,
              locale: Locale(locale),
              child: widget,
            );
            // Rebuild the widget to reflect changes
            setState(() {});
          }
        },
        itemBuilder: (BuildContext context) {
          return languages.keys.map((String language) {
            return PopupMenuItem<String>(
              value: language,
              child: Text(
                language,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            );
          }).toList();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the current localizations
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // Background with moving neon gradient effect
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: NeonGradientPainter(_animation.value),
                );
              },
            ),
          ),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: Colors.black.withOpacity(0.8),
            ),
          ),

          // Main UI
          Column(
            children: <Widget>[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildLanguageButton(),
                ],
              ),
              Stack(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.00,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(50.0),
                      ),
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.2,
                    width: double.infinity,
                    color: Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        ElevatedButton(
                          onPressed: () {
                            _pickImage(ImageSource.gallery);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.openGallery, // Changed from l10n.selectImage to l10n.openGallery
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.image,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _pickImage(ImageSource.camera);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.startCamera, // Use localized string
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _selectedImage == null
                  ? SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Image.asset('assets/images/pick1.png'),
                    )
                  : Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.all(15),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
              if (_selectedImage != null)
                detecting
                    ? const SpinKitWave(
                        color: Colors.white,
                        size: 29,
                      )
                    : Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 20),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: () {
                            detectDisease();
                          },
                          child: Text(
                            l10n.detect, // Use localized string
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
              if (diseaseName != '')
                Column(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * 0.2,
                      padding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DefaultTextStyle(
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16),
                            child: AnimatedTextKit(
                                isRepeatingAnimation: false,
                                repeatForever: false,
                                displayFullTextOnTap: true,
                                totalRepeatCount: 1,
                                animatedTexts: [
                                  TyperAnimatedText(
                                    diseaseName.trim(),
                                  ),
                                ]),
                          )
                        ],
                      ),
                    ),
                    precautionLoading
                        ? const SpinKitWave(
                            color: Colors.white,
                            size: 30,
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () {
                              showPrecautions();
                            },
                            child: Text(
                              l10n.precaution, // Use localized string
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ],
                ),
              const SizedBox(height: 30),
            ],
          ),
        ],
      ),
    );
  }
}

class NeonGradientPainter extends CustomPainter {
  final double animationValue;

  NeonGradientPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.pink.withOpacity(0.8),
          Colors.purple.withOpacity(0.8),
          Colors.blue.withOpacity(0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [animationValue, animationValue + 0.3, animationValue + 0.6],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

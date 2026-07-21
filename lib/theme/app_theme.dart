import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Garden / game palette ──────────────────────────────────────────────────
  static const gardenGreen      = Color(0xFF2B5E3F);
  static const gardenGreenDark  = Color(0xFF1A3D29);
  static const gardenGreenMid   = Color(0xFF3A7A54);
  static const potTerracotta    = Color(0xFFC4694A);
  static const potTerracottaDark= Color(0xFF9E4F35);
  static const potTerracottaLight=Color(0xFFD9896E);
  static const shelfWoodLight   = Color(0xFFD4A86A);
  static const shelfWoodMid     = Color(0xFFA87840);
  static const shelfWoodDark    = Color(0xFF7A5428);
  static const floorWoodLight   = Color(0xFFDEB887);
  static const floorWoodMid     = Color(0xFFC49A6C);
  static const phoneScreen      = Color(0xFF1C1C2E);
  static const phoneScreenLight = Color(0xFF2C2C3E);
  static const messageBubble    = Color(0xFF3A7A54);
  static const notifRed         = Color(0xFFE53935);

  // ── Base warm palette ──────────────────────────────────────────────────────
  static const cream = Color(0xFFF5E6D3);
  static const brown = Color(0xFF8B5E3C);
  static const brownLight = Color(0xFFAD7C52);
  static const brownDark = Color(0xFF5C3A1E);
  static const terracotta = Color(0xFFE8A87C);
  static const terracottaDark = Color(0xFFD4845A);
  static const sage = Color(0xFF7A9E7E);
  static const sageDark = Color(0xFF5A7A5E);
  static const sageLight = Color(0xFFA8C5A0);
  static const parchment = Color(0xFFFDF3E7);
  static const warmWhite = Color(0xFFFEF9F4);
  static const inkBrown = Color(0xFF3D2010);
  static const shadow = Color(0x33000000);

  // Accent pops
  static const mint = Color(0xFF9DD4C0);
  static const mintLight = Color(0xFFD4EFE9);
  static const pink = Color(0xFFF4A7C0);
  static const pinkLight = Color(0xFFFDE0EC);
  static const lilac = Color(0xFFCEB5D4);
  static const lilacLight = Color(0xFFEEE0F5);

  // Original flower accent colors
  static const roseRed = Color(0xFFE8576A);
  static const daisyYellow = Color(0xFFF5CE5A);
  static const lilyWhite = Color(0xFFEFD5D0);
  static const sunflowerGold = Color(0xFFFFB830);
  static const lavenderPurple = Color(0xFFB49FCC);
  static const tulipPink = Color(0xFFEC8FAC);
  static const orchidDeep = Color(0xFF9B5E8A);
  static const carnationCoral = Color(0xFFE87E6E);
  static const wildflowerBlue = Color(0xFF7EB8D4);
  static const babysBreathWhite = Color(0xFFD8CFEF);

  // New flower accent colors
  static const peonPink = Color(0xFFE891B0);
  static const ranunculusOrange = Color(0xFFE8956A);
  static const anemoneDeep = Color(0xFF7B5EA7);
  static const proteaRust = Color(0xFFC4694A);
  static const sweetPeaPink = Color(0xFFEF8FB0);
  static const lisianthusLavender = Color(0xFF8E78B5);
  static const gerberaOrange = Color(0xFFFF7A5C);
  static const snapdragonViolet = Color(0xFF9966CC);
  static const freesiaYellow = Color(0xFFF0D060);
  static const hyacinthBlue = Color(0xFF7799CC);
  static const cosmosPink = Color(0xFFE87898);
  static const zinniaOrange = Color(0xFFE8680A);
  static const marigoldOrange = Color(0xFFFF9800);
  static const chrysanthemumCream = Color(0xFFE8D8B0);
  static const wisteriaDeep = Color(0xFF7B5EA7);
  static const staticeBlue = Color(0xFF9090BC);
  static const eucalyptusGreen = Color(0xFF6B9E6B);
  static const fernGreen = Color(0xFF4A8050);
  static const berryDeep = Color(0xFF6A4080);
  static const thistlePurple = Color(0xFF886699);

  // Seasonal / event-exclusive flowers
  static const gardeniaBlush    = Color(0xFFF2C4D8); // Valentine's gardenia
  static const amaryllisCrimson = Color(0xFFB83A52); // Winter Blooms amaryllis
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.brown,
          onPrimary: AppColors.warmWhite,
          secondary: AppColors.terracotta,
          onSecondary: AppColors.inkBrown,
          error: const Color(0xFFE53935),
          onError: Colors.white,
          surface: AppColors.cream,
          onSurface: AppColors.inkBrown,
        ),
        scaffoldBackgroundColor: AppColors.cream,
        textTheme: GoogleFonts.nunitoTextTheme().copyWith(
          displayLarge: GoogleFonts.playfairDisplay(
            color: AppColors.inkBrown,
            fontWeight: FontWeight.bold,
          ),
          displayMedium: GoogleFonts.playfairDisplay(
            color: AppColors.inkBrown,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: GoogleFonts.playfairDisplay(
            color: AppColors.inkBrown,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: GoogleFonts.nunito(color: AppColors.inkBrown),
          bodyMedium: GoogleFonts.nunito(color: AppColors.inkBrown),
          labelLarge: GoogleFonts.nunito(
            color: AppColors.inkBrown,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brown,
            foregroundColor: AppColors.warmWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            elevation: 4,
            shadowColor: AppColors.brownDark.withValues(alpha: 0.4),
          ),
        ),
      );
}

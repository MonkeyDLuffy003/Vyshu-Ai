class PdfResult {
  final String  message;
  final String? filePath;
  PdfResult({required this.message, this.filePath});
}

class PdfMakerSkill {
  static Future<PdfResult> buildResume() async {
    return PdfResult(
      message: "📄 Resume builder ready!\n"
          "Say 'my profile: [your details]' and I will "
          "start building your resume 💙");
  }

  static Future<PdfResult> makePdf(
      String title, String content) async {
    return PdfResult(
      message: "📄 PDF '$title' coming soon!\n"
          "Full PDF export in V4.1 💙");
  }
}

abstract class ExportService {
  Future<String> exportTapeAsPdf(String sessionId);
  Future<String> exportTapeAsExcel(String sessionId);
}

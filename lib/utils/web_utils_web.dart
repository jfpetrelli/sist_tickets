// Implementación web usando dart:html
import 'dart:html' as html;

String? getCurrentPath() {
  return html.window.location.pathname;
}

import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFFE74C3C);
const kSecondaryColor = Color(0xFFF1948A);
const kBackgroundColor = Color(0xFFF5F5F5);
const kTextColor = Color(0xFF333333);
const kErrorColor = Color(0xFFE57373);
const kSuccessColor = Color(0xFF81C784);
const kWarningColor = Color(0xFFFFB74D);

const Color kAccentColor = Color(0xFFE74C3C);
const Color kLightTextColor = Color(0xFF7F8C8D);

// Define el radio del borde una sola vez para consistencia
const BorderRadius _inputBorderRadius = BorderRadius.all(Radius.circular(8.0));

// Define el color de borde
const Color _inputBorderColor =
    Color(0xFFE0E0E0); // Equivalente a Colors.grey.shade300
const Color _outlineDeactivatedBorderColor =
    Color(0xFFEEEEEE); // Equivalente a Colors.grey.shade200
// Define el estilo de borde base
const OutlineInputBorder _inputBorderStyle = OutlineInputBorder(
  borderRadius: _inputBorderRadius,
  borderSide: BorderSide(
      color: _inputBorderColor, width: 1.0), // Borde sutil por defecto
);

// Define el Input Decoration Theme
const InputDecorationTheme kInputDecorationTheme = InputDecorationTheme(
  // Aspecto General
  filled: true, // Habilita el color de fondo
  fillColor:
      Colors.white, // Fondo blanco (o un gris muy claro como Colors.grey[50])
  contentPadding: EdgeInsets.symmetric(
      horizontal: 16.0, vertical: 12.0), // Ajusta el padding interno

  // Estilo de Bordes
  border:
      _inputBorderStyle, // Borde base (cuando no está enfocado ni hay error)
  enabledBorder:
      _inputBorderStyle, // Borde cuando está habilitado pero no enfocado
  focusedBorder: OutlineInputBorder(
    // Borde cuando está enfocado
    borderRadius: _inputBorderRadius,
    borderSide: BorderSide(
        color: kPrimaryColor, width: 1.5), // Resalta con color primario
  ),
  errorBorder: OutlineInputBorder(
    // Borde cuando hay error
    borderRadius: _inputBorderRadius,
    borderSide:
        BorderSide(color: kErrorColor, width: 1.0), // Usa el color de error
  ),
  focusedErrorBorder: OutlineInputBorder(
    // Borde con error y enfocado
    borderRadius: _inputBorderRadius,
    borderSide: BorderSide(color: kErrorColor, width: 1.5), // Resalta error
  ),
  disabledBorder: OutlineInputBorder(
    // Borde cuando está deshabilitado (opcional)
    borderRadius: _inputBorderRadius,
    borderSide: BorderSide(color: _outlineDeactivatedBorderColor, width: 1.0),
  ),

  // Estilo de Etiquetas y Hints
  labelStyle: TextStyle(color: Colors.grey), // Color de la etiqueta flotante
  floatingLabelStyle:
      TextStyle(color: kPrimaryColor), // Color de la etiqueta al flotar/enfocar
  hintStyle: TextStyle(
      color: Color(
          0xFFBDBDBD)), // Color del texto de placeholder (equivalente a Colors.grey.shade400)
  errorStyle:
      TextStyle(color: kErrorColor, fontSize: 12), // Estilo del texto de error

  // Estilo de Iconos
  prefixIconColor: Colors.grey, // Color de los iconos prefijo por defecto
  // Puedes usar MaterialStateColor para cambiar el color del icono cuando está enfocado:
  // (Descomenta si quieres este efecto)
  /*
  prefixIconColor: MaterialStateColor.resolveWith((states) {
    if (states.contains(MaterialState.focused)) {
      return kPrimaryColor; // Color del icono cuando el campo está enfocado
    }
    return Colors.grey; // Color por defecto
  }),
  */
  suffixIconColor: Colors.grey, // Color de los iconos sufijo
);

final kButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: kPrimaryColor,
  foregroundColor: Colors.white,
  minimumSize: const Size(double.infinity, 50),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
  elevation: 0,
);

final kTextFieldDecoration = InputDecoration(
  filled: true,
  fillColor: Colors.white,
  hintStyle: TextStyle(color: Colors.grey[500]),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: kPrimaryColor, width: 1),
  ),
);

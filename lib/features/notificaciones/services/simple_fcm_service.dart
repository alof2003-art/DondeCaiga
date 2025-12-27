import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio simplificado para debuggear FCM token
class SimpleFCMService {
  static final SimpleFCMService _instance = SimpleFCMService._internal();
  factory SimpleFCMService() => _instance;
  SimpleFCMService._internal();

  /// Inicializar y obtener token FCM
  static Future<void> initializeAndGetToken() async {
    try {
      debugPrint('🔥 === INICIANDO SIMPLE FCM SERVICE ===');

      // 1. Verificar que Firebase esté inicializado
      debugPrint('🔥 Paso 1: Verificando Firebase...');

      // 2. Solicitar permisos
      debugPrint('🔥 Paso 2: Solicitando permisos...');
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('🔥 Permisos resultado: ${settings.authorizationStatus}');

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('❌ Permisos denegados');
        return;
      }

      // 3. Obtener token FCM
      debugPrint('🔥 Paso 3: Obteniendo token FCM...');
      final token = await FirebaseMessaging.instance.getToken();

      if (token == null) {
        debugPrint('❌ No se pudo obtener token FCM');
        return;
      }

      debugPrint('🔥 Token FCM obtenido: ${token.substring(0, 30)}...');

      // 4. Verificar usuario actual
      debugPrint('🔥 Paso 4: Verificando usuario...');
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        debugPrint('❌ No hay usuario logueado');
        return;
      }

      debugPrint('🔥 Usuario ID: ${user.id}');

      // 5. Guardar token en Supabase
      debugPrint('🔥 Paso 5: Guardando token en Supabase...');

      try {
        final response = await Supabase.instance.client
            .from('users_profiles')
            .update({'fcm_token': token})
            .eq('id', user.id)
            .select();

        debugPrint('🔥 Respuesta de Supabase: $response');
        debugPrint('✅ TOKEN FCM GUARDADO EXITOSAMENTE');
      } catch (supabaseError) {
        debugPrint('❌ Error de Supabase: $supabaseError');

        // Intentar método alternativo
        debugPrint('🔥 Intentando método alternativo...');

        try {
          await Supabase.instance.client.rpc(
            'update_fcm_token',
            params: {'user_id': user.id, 'new_token': token},
          );

          debugPrint('✅ TOKEN GUARDADO CON RPC');
        } catch (rpcError) {
          debugPrint('❌ Error con RPC: $rpcError');
        }
      }
    } catch (e) {
      debugPrint('❌ Error general en SimpleFCMService: $e');
      debugPrint('📋 Stack trace: ${StackTrace.current}');
    }
  }

  /// Verificar estado actual del token
  static Future<void> checkTokenStatus() async {
    try {
      debugPrint('🔍 === VERIFICANDO ESTADO DEL TOKEN ===');

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('❌ No hay usuario logueado');
        return;
      }

      // Verificar token en Firebase
      final firebaseToken = await FirebaseMessaging.instance.getToken();
      debugPrint('🔥 Token en Firebase: ${firebaseToken?.substring(0, 30)}...');

      // Verificar token en Supabase
      final response = await Supabase.instance.client
          .from('users_profiles')
          .select('fcm_token')
          .eq('id', user.id)
          .single();

      final supabaseToken = response['fcm_token'] as String?;
      debugPrint('💾 Token en Supabase: ${supabaseToken?.substring(0, 30)}...');

      if (firebaseToken != null && supabaseToken != null) {
        if (firebaseToken == supabaseToken) {
          debugPrint('✅ TOKENS COINCIDEN - TODO CORRECTO');
        } else {
          debugPrint('⚠️ TOKENS NO COINCIDEN - ACTUALIZANDO...');
          await initializeAndGetToken();
        }
      } else {
        debugPrint('❌ FALTA TOKEN - INICIALIZANDO...');
        await initializeAndGetToken();
      }
    } catch (e) {
      debugPrint('❌ Error al verificar token: $e');
    }
  }
}

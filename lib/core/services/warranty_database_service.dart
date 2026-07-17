import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';

final warrantyDatabaseServiceProvider = Provider<WarrantyDatabaseService>((ref) {
  return WarrantyDatabaseService(Supabase.instance.client);
});

class WarrantyDatabaseService {
  final SupabaseClient _supabase;

  WarrantyDatabaseService(this._supabase);

  /// Saves a warranty record in the "warranties" table. Returns generated ID.
  Future<String> saveWarranty(WarrantyModel warranty) async {
    try {
      final payload = warranty.toJson();
      payload.remove('id');

      final response = await _supabase
          .from('warranties')
          .insert(payload)
          .select('id')
          .single();

      return response['id'].toString();
    } catch (e) {
      throw Exception('Supabase saveWarranty failed: $e');
    }
  }

  /// Fetches a single warranty by ID.
  Future<WarrantyModel?> fetchWarranty(String id) async {
    try {
      final response = await _supabase
          .from('warranties')
          .select()
          .eq('id', int.tryParse(id) ?? id)
          .maybeSingle();

      if (response == null) return null;
      return WarrantyModel.fromJson(response);
    } catch (e) {
      throw Exception('Supabase fetchWarranty failed: $e');
    }
  }

  /// Fetches all warranty records for a given user.
  Future<List<WarrantyModel>> fetchAllWarranties(String userId) async {
    try {
      final response = await _supabase
          .from('warranties')
          .select()
          .eq('user_id', userId)
          .order('expiry_date', ascending: true);

      final List<dynamic> list = response as List<dynamic>? ?? [];
      return list.map((item) => WarrantyModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Supabase fetchAllWarranties failed: $e');
    }
  }

  /// Updates an existing warranty record.
  Future<void> updateWarranty(WarrantyModel warranty) async {
    try {
      if (warranty.id == null) throw Exception('Cannot update warranty without an ID.');
      
      final payload = warranty.toJson();
      payload.remove('id');

      await _supabase
          .from('warranties')
          .update(payload)
          .eq('id', int.tryParse(warranty.id!) ?? warranty.id!);
    } catch (e) {
      throw Exception('Supabase updateWarranty failed: $e');
    }
  }

  /// Deletes an existing warranty record by ID.
  Future<void> deleteWarranty(String id) async {
    try {
      await _supabase
          .from('warranties')
          .delete()
          .eq('id', int.tryParse(id) ?? id);
    } catch (e) {
      throw Exception('Supabase deleteWarranty failed: $e');
    }
  }
}

import '../entities/business_entity.dart';

abstract class BusinessRepository {
  Future<BusinessEntity?> getBusinessForUser(String userId);
  Future<BusinessEntity> createBusiness(String userId, String name, String type);
  Future<BusinessEntity> updateBusiness(String businessId, String name, String type);
  Future<void> deleteAccount();
}

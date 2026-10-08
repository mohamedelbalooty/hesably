import 'package:flutter_test/flutter_test.dart';
import 'package:hesably_mobile/features/transactions/domain/models/category.dart';
import 'package:hesably_mobile/features/categories/domain/repositories/category_repository.dart';
import 'package:hesably_mobile/features/categories/presentation/bloc/category_management_bloc.dart';

class MockCategoryRepository implements CategoryRepository {
  List<Category> categoriesToReturn = [];
  bool throwError = false;

  @override
  Future<Category> addCustomCategory(String businessId, String name) async {
    if (throwError) throw Exception('Create error');
    return Category(id: 'new', businessId: businessId, name: name, isDefault: false, isHidden: false, createdAt: DateTime.now());
  }

  @override
  Future<void> deleteCustomCategory(String categoryId) async {
    if (throwError) throw Exception('Delete error');
  }

  @override
  Future<List<Category>> getCategories(String businessId) async {
    if (throwError) throw Exception('Fetch error');
    return categoriesToReturn;
  }

  @override
  Future<List<Category>> getActiveCategories(String businessId) async {
    return categoriesToReturn.where((c) => !c.isHidden).toList();
  }

  @override
  Future<void> reassignAndDeleteCategory(String oldCategoryId, String newCategoryId) async {
    if (throwError) throw Exception('Reassign error');
  }
  
  @override
  Future<void> hideDefaultCategory(String categoryId) async {
     if (throwError) throw Exception('Hide error');
  }

  @override
  Future<void> unhideDefaultCategory(String categoryId) async {
     if (throwError) throw Exception('Unhide error');
  }

  @override
  Future<void> reassignTransactions(String oldCategoryId, String newCategoryId) async {
    if (throwError) throw Exception('Reassign error');
  }
}

void main() {
  late CategoryManagementBloc bloc;
  late MockCategoryRepository mockRepo;
  final testCategory = Category(
    id: '1',
    businessId: 'b1',
    name: 'Test',
    isDefault: false,
    isHidden: false,
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockRepo = MockCategoryRepository();
    bloc = CategoryManagementBloc(mockRepo);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is CategoryManagementInitial', () {
    expect(bloc.state, isA<CategoryManagementInitial>());
  });

  test('emits Loading then Loaded on LoadCategories', () async {
    mockRepo.categoriesToReturn = [testCategory];

    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<CategoryManagementLoading>(),
        isA<CategoryManagementLoaded>().having((s) => s.categories.length, 'length', 1),
      ]),
    );

    bloc.add(const LoadCategories('b1'));
  });

  test('emits Loaded with new category on AddCustomCategory when already loaded', () async {
    bloc.emit(CategoryManagementLoaded([testCategory]));

    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<CategoryManagementLoaded>().having((s) => s.categories.length, 'length', 2),
      ]),
    );

    bloc.add(const AddCustomCategory('b1', 'New Cat'));
  });

  test('emits Loaded with hidden category on ToggleCategoryVisibility', () async {
    bloc.emit(CategoryManagementLoaded([testCategory]));

    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<CategoryManagementLoaded>().having((s) => s.categories.first.isHidden, 'isHidden', true),
      ]),
    );

    bloc.add(const ToggleCategoryVisibility('1', true));
  });
  
  test('emits Loaded without deleted category on DeleteCustomCategory', () async {
    bloc.emit(CategoryManagementLoaded([testCategory]));

    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<CategoryManagementLoaded>().having((s) => s.categories.length, 'length', 0),
      ]),
    );

    bloc.add(const DeleteCustomCategory('1'));
  });

  test('emits Error when operations fail on LoadCategories', () async {
    mockRepo.throwError = true;

    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<CategoryManagementLoading>(),
        isA<CategoryManagementError>(),
      ]),
    );

    bloc.add(const LoadCategories('b1'));
  });
}

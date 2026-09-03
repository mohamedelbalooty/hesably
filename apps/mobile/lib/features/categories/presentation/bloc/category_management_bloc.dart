import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hesably_mobile/features/transactions/domain/models/category.dart';
import 'package:hesably_mobile/features/categories/domain/repositories/category_repository.dart';

// --- Events ---
abstract class CategoryManagementEvent extends Equatable {
  const CategoryManagementEvent();
  @override
  List<Object?> get props => [];
}

class LoadCategories extends CategoryManagementEvent {
  final String businessId;
  const LoadCategories(this.businessId);
  @override
  List<Object?> get props => [businessId];
}

class ToggleCategoryVisibility extends CategoryManagementEvent {
  final String categoryId;
  final bool hide;
  const ToggleCategoryVisibility(this.categoryId, this.hide);
  @override
  List<Object?> get props => [categoryId, hide];
}

class AddCustomCategory extends CategoryManagementEvent {
  final String businessId;
  final String name;
  const AddCustomCategory(this.businessId, this.name);
  @override
  List<Object?> get props => [businessId, name];
}

class DeleteCustomCategory extends CategoryManagementEvent {
  final String categoryId;
  final String? reassignToCategoryId;
  
  const DeleteCustomCategory(this.categoryId, {this.reassignToCategoryId});
  @override
  List<Object?> get props => [categoryId, reassignToCategoryId];
}

// --- States ---
abstract class CategoryManagementState extends Equatable {
  const CategoryManagementState();
  @override
  List<Object?> get props => [];
}

class CategoryManagementInitial extends CategoryManagementState {}

class CategoryManagementLoading extends CategoryManagementState {}

class CategoryManagementLoaded extends CategoryManagementState {
  final List<Category> categories;
  const CategoryManagementLoaded(this.categories);
  @override
  List<Object?> get props => [categories];
}

class CategoryManagementError extends CategoryManagementState {
  final String error;
  const CategoryManagementError(this.error);
  @override
  List<Object?> get props => [error];
}

// --- Bloc ---
class CategoryManagementBloc extends Bloc<CategoryManagementEvent, CategoryManagementState> {
  final CategoryRepository _repository;

  CategoryManagementBloc(this._repository) : super(CategoryManagementInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<ToggleCategoryVisibility>(_onToggleCategoryVisibility);
    on<AddCustomCategory>(_onAddCustomCategory);
    on<DeleteCustomCategory>(_onDeleteCustomCategory);
  }

  Future<void> _onLoadCategories(LoadCategories event, Emitter<CategoryManagementState> emit) async {
    emit(CategoryManagementLoading());
    try {
      final categories = await _repository.getCategories(event.businessId);
      emit(CategoryManagementLoaded(categories));
    } catch (e) {
      emit(CategoryManagementError(e.toString()));
    }
  }

  Future<void> _onToggleCategoryVisibility(ToggleCategoryVisibility event, Emitter<CategoryManagementState> emit) async {
    if (state is! CategoryManagementLoaded) return;
    
    final currentState = state as CategoryManagementLoaded;
    try {
      if (event.hide) {
        await _repository.hideDefaultCategory(event.categoryId);
      } else {
        await _repository.unhideDefaultCategory(event.categoryId);
      }
      
      // Update local state optimistically
      final updatedCategories = currentState.categories.map((c) {
        if (c.id == event.categoryId) {
          return c.copyWith(isHidden: event.hide);
        }
        return c;
      }).toList();
      
      emit(CategoryManagementLoaded(updatedCategories));
    } catch (e) {
      emit(CategoryManagementError(e.toString()));
      // Re-emit previous state to recover UI
      emit(currentState);
    }
  }

  Future<void> _onAddCustomCategory(AddCustomCategory event, Emitter<CategoryManagementState> emit) async {
    if (state is! CategoryManagementLoaded) return;
    final currentState = state as CategoryManagementLoaded;
    
    try {
      final newCat = await _repository.addCustomCategory(event.businessId, event.name);
      
      final updatedCategories = List<Category>.from(currentState.categories)..add(newCat);
      emit(CategoryManagementLoaded(updatedCategories));
    } catch (e) {
      emit(CategoryManagementError(e.toString()));
      emit(currentState);
    }
  }

  Future<void> _onDeleteCustomCategory(DeleteCustomCategory event, Emitter<CategoryManagementState> emit) async {
    if (state is! CategoryManagementLoaded) return;
    final currentState = state as CategoryManagementLoaded;
    
    try {
      if (event.reassignToCategoryId != null) {
        await _repository.reassignTransactions(event.categoryId, event.reassignToCategoryId!);
      }
      
      await _repository.deleteCustomCategory(event.categoryId);
      
      final updatedCategories = currentState.categories.where((c) => c.id != event.categoryId).toList();
      emit(CategoryManagementLoaded(updatedCategories));
    } catch (e) {
      emit(CategoryManagementError(e.toString()));
      emit(currentState);
    }
  }
}

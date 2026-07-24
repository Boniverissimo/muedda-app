import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/categories_providers.dart';
import '../../../../core/utils/category_visuals.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialization = ref.watch(categoriesInitializationProvider);

    return initialization.when(
      loading: () {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      error: (error, stackTrace) {
        return Scaffold(
          appBar: AppBar(title: const Text('Categorias')),
          body: Center(child: Text('Erro ao preparar categorias: $error')),
        );
      },
      data: (_) {
        return const _CategoriesContent();
      },
    );
  }
}

class _CategoriesContent extends ConsumerWidget {
  const _CategoriesContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseCategories = ref.watch(expenseCategoriesStreamProvider);

    final incomeCategories = ref.watch(incomeCategoriesStreamProvider);

    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Categorias'),
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.arrow_downward), text: 'Despesas'),
                  Tab(icon: Icon(Icons.arrow_upward), text: 'Receitas'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _CategoriesList(
                  categoriesAsync: expenseCategories,
                  emptyMessage: 'Nenhuma categoria de despesa.',
                  onCategoryTap: (category) {
                    _showCategoryOptions(
                      context: context,
                      ref: ref,
                      category: category,
                    );
                  },
                ),
                _CategoriesList(
                  categoriesAsync: incomeCategories,
                  emptyMessage: 'Nenhuma categoria de receita.',
                  onCategoryTap: (category) {
                    _showCategoryOptions(
                      context: context,
                      ref: ref,
                      category: category,
                    );
                  },
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: null,
              onPressed: () {
                final tabIndex = DefaultTabController.of(context).index;

                _showCategoryDialog(
                  context: context,
                  ref: ref,
                  initialType: tabIndex == 0 ? 'expense' : 'income',
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Nova categoria'),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCategoryOptions({
    required BuildContext context,
    required WidgetRef ref,
    required Category category,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();

                  _showCategoryDialog(
                    context: context,
                    ref: ref,
                    category: category,
                    initialType: category.type,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Excluir'),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();

                  _confirmDeleteCategory(
                    context: context,
                    ref: ref,
                    category: category,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancelar'),
                onTap: () {
                  Navigator.of(bottomSheetContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCategoryDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String initialType,
    Category? category,
  }) async {
    final isEditing = category != null;

    final nameController = TextEditingController(text: category?.name ?? '');

    var selectedType = category?.type ?? initialType;

    var selectedIconName =
        category?.iconName ?? _defaultIconForType(selectedType);

    var selectedColorHex =
        category?.colorHex ?? _defaultColorForType(selectedType);

    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final selectedColor = CategoryVisuals.colorFromHex(
              selectedColorHex,
            );

            return AlertDialog(
              title: Text(isEditing ? 'Editar categoria' : 'Nova categoria'),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        enabled: !isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Nome da categoria',
                          hintText: 'Ex.: Alimentação',
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        items: const [
                          DropdownMenuItem(
                            value: 'expense',
                            child: Text('Despesa'),
                          ),
                          DropdownMenuItem(
                            value: 'income',
                            child: Text('Receita'),
                          ),
                        ],
                        onChanged: isSaving
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }

                                setState(() {
                                  selectedType = value;

                                  if (category == null) {
                                    selectedIconName = _defaultIconForType(
                                      selectedType,
                                    );

                                    selectedColorHex = _defaultColorForType(
                                      selectedType,
                                    );
                                  }
                                });
                              },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Ícone',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: CategoryVisuals.icons.entries.map((entry) {
                          final isSelected = entry.key == selectedIconName;

                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: isSaving
                                ? null
                                : () {
                                    setState(() {
                                      selectedIconName = entry.key;
                                    });
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? selectedColor.withValues(alpha: 0.18)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  width: isSelected ? 2 : 1,
                                  color: isSelected
                                      ? selectedColor
                                      : Theme.of(context).dividerColor,
                                ),
                              ),
                              child: Icon(
                                entry.value,
                                color: isSelected ? selectedColor : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Cor',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: CategoryVisuals.colors.map((colorHex) {
                          final color = CategoryVisuals.colorFromHex(colorHex);

                          final isSelected = colorHex == selectedColorHex;

                          return InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: isSaving
                                ? null
                                : () {
                                    setState(() {
                                      selectedColorHex = colorHex;
                                    });
                                  },
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Pré-visualização',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: selectedColor.withValues(
                                alpha: 0.16,
                              ),
                              child: Icon(
                                CategoryVisuals.iconFromName(selectedIconName),
                                color: selectedColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                nameController.text.trim().isEmpty
                                    ? 'Nome da categoria'
                                    : nameController.text.trim(),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              selectedType == 'income' ? 'Receita' : 'Despesa',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameController.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Informe o nome da categoria.'),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isSaving = true;
                          });

                          final repository = ref.read(
                            categoriesRepositoryProvider,
                          );

                          try {
                            if (isEditing) {
                              await repository.updateCategory(
                                id: category.id,
                                name: name,
                                type: selectedType,
                                iconName: selectedIconName,
                                colorHex: selectedColorHex,
                              );
                            } else {
                              await repository.createCategory(
                                name: name,
                                type: selectedType,
                                iconName: selectedIconName,
                                colorHex: selectedColorHex,
                              );
                            }

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEditing
                                        ? 'Categoria atualizada com sucesso.'
                                        : 'Categoria criada com sucesso.',
                                  ),
                                ),
                              );
                            }
                          } catch (error) {
                            if (dialogContext.mounted) {
                              setState(() {
                                isSaving = false;
                              });
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Erro ao salvar categoria: $error',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Atualizar' : 'Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _defaultIconForType(String type) {
    return type == 'income' ? 'payments' : 'shopping_bag';
  }

  String _defaultColorForType(String type) {
    return type == 'income' ? '#4CAF50' : '#F44336';
  }

  Future<void> _confirmDeleteCategory({
    required BuildContext context,
    required WidgetRef ref,
    required Category category,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir categoria'),
          content: Text(
            'Deseja realmente excluir a categoria '
            '"${category.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final repository = ref.read(categoriesRepositoryProvider);

    try {
      await repository.deleteCategory(category.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoria excluída com sucesso.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível excluir a categoria: $error'),
          ),
        );
      }
    }
  }
}

class _CategoriesList extends StatelessWidget {
  const _CategoriesList({
    required this.categoriesAsync,
    required this.emptyMessage,
    required this.onCategoryTap,
  });

  final AsyncValue<List<Category>> categoriesAsync;
  final String emptyMessage;
  final ValueChanged<Category> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Center(child: Text(emptyMessage));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          separatorBuilder: (context, index) {
            return const SizedBox(height: 8);
          },
          itemBuilder: (context, index) {
            final category = categories[index];

            final fallbackColor = category.type == 'income'
                ? Colors.green
                : Colors.red;

            final categoryColor = CategoryVisuals.colorFromHex(
              category.colorHex,
              fallback: fallbackColor,
            );

            final categoryIcon = CategoryVisuals.iconFromName(
              category.iconName,
            );

            return Card(
              child: ListTile(
                onTap: () {
                  onCategoryTap(category);
                },
                leading: CircleAvatar(
                  backgroundColor: categoryColor.withValues(alpha: 0.16),
                  child: Icon(categoryIcon, color: categoryColor),
                ),
                title: Text(category.name),
                subtitle: Text(
                  category.type == 'income' ? 'Receita' : 'Despesa',
                ),
                trailing: const Icon(Icons.more_vert),
              ),
            );
          },
        );
      },
      loading: () {
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, stackTrace) {
        return Center(child: Text('Erro ao carregar categorias: $error'));
      },
    );
  }
}

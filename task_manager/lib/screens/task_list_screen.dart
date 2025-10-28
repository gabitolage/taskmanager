import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';
import '../services/sensor_service.dart';
import '../services/location_service.dart';
import '../screens/task_form_screen.dart';


class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  List<Category> _categories = [];
  String _filter = 'all'; // all, completed, pending
  String? _categoryFilter; // Novo filtro por categoria
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkOverdueTasksOnStart();
    _setupShakeDetection(); 
  }

  @override
  void dispose() {
    SensorService.instance.stop(); // PARAR SHAKE
    super.dispose();
  }

  // SHAKE DETECTION
  void _setupShakeDetection() {
    SensorService.instance.startShakeDetection(() {
      _showShakeDialog();
    });
  }

  void _showShakeDialog() {
    final pendingTasks = _tasks.where((t) => !t.completed).toList();
    
    if (pendingTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Nenhuma tarefa pendente!'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.vibration, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(child: Text('Shake detectado!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecione uma tarefa para completar:'),
            const SizedBox(height: 16),
            ...pendingTasks.take(3).map((task) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => _completeTaskByShake(task),
              ),
            )),
            if (pendingTasks.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+ ${pendingTasks.length - 3} outras',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeTaskByShake(Task task) async {
    try {
      final updated = task.copyWith(
        completed: true,
        completedAt: DateTime.now(),
        completedBy: 'shake',
      );

      await DatabaseService.instance.update(updated);
      Navigator.pop(context);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ "${task.title}" completa via shake!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Método para verificar tarefas vencidas ao iniciar o app
  void _checkOverdueTasksOnStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData(); // Garantir que as tarefas estão carregadas
      
      final overdueTasks = _tasks.where((t) => t.isOverdue && !t.completed).toList();
      
      if (overdueTasks.isNotEmpty && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text('Tarefas Vencidas'),
              ],
            ),
            content: Text(
              'Você tem ${overdueTasks.length} tarefa(s) vencida(s). '
              'Deseja visualizá-las agora?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Depois'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _filter = 'pending');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Visualizar'),
              ),
            ],
          ),
        );
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final tasks = await DatabaseService.instance.readAll();
      final categories = await DatabaseService.instance.readAllCategories();
      
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _tasks = [];
          _categories = [];
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Task> get _filteredTasks {
    List<Task> filtered = _tasks;

    // Aplicar filtro de status
    switch (_filter) {
      case 'completed':
        filtered = filtered.where((t) => t.completed).toList();
        break;
      case 'pending':
        filtered = filtered.where((t) => !t.completed).toList();
        break;
      case 'nearby':
        // Implementar filtro de proximidade
        break;
    }

    // Aplicar filtro de categoria
    if (_categoryFilter != null) {
      filtered = filtered.where((t) => t.categoryId == _categoryFilter).toList();
    }

    return filtered;
  }

  Future<void> _toggleTask(Task task) async {
    final updated = task.copyWith(completed: !task.completed);
    await DatabaseService.instance.update(updated);
    await _loadData();
  }

  Future<void> _filterByNearby() async {
    final position = await LocationService.instance.getCurrentLocation();
    
    if (position == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Não foi possível obter localização'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final nearbyTasks = await DatabaseService.instance.getTasksNearLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusInMeters: 1000,
    );

    setState(() {
      _tasks = nearbyTasks;
      _filter = 'nearby';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 ${nearbyTasks.length} tarefa(s) próxima(s)'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }


  Future<void> _deleteTask(Task task) async {
    // Confirmar exclusão
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.instance.delete(task.id);
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarefa excluída'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _openTaskForm([Task? task]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: task),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  // Método para obter categoria por ID
  Category? _getCategoryById(String? categoryId) {
    if (categoryId == null) return null;
    return _categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => Category(name: '', color: ''),
    );
  }

  // Método auxiliar para converter cor hexadecimal
  Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll("#", "");
      if (hexColor.length == 6) {
        hexColor = "FF$hexColor";
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

    Future<void> _toggleComplete(Task task) async {
    try {
      final updated = task.copyWith(
        completed: !task.completed,
        completedAt: !task.completed ? DateTime.now() : null,
        completedBy: !task.completed ? 'manual' : null,
      );

      await DatabaseService.instance.update(updated);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filteredTasks;
    final stats = _calculateStats();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Filtro de Status
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.list),
                    SizedBox(width: 8),
                    Text('Todas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Row(
                  children: [
                    Icon(Icons.pending_actions),
                    SizedBox(width: 8),
                    Text('Pendentes'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Row(
                  children: [
                    Icon(Icons.check_circle),
                    SizedBox(width: 8),
                    Text('Concluídas'),
                  ],
                ),
              ),
            ],
          ),
          
          // Filtro de Categoria
          if (_categories.isNotEmpty)
            PopupMenuButton<String?>(
              icon: const Icon(Icons.category),
              onSelected: (value) => setState(() => _categoryFilter = value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.clear_all),
                      SizedBox(width: 8),
                      Text('Todas Categorias'),
                    ],
                  ),
                ),
                ..._categories.map((category) {
                  return PopupMenuItem(
                    value: category.id,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _parseColor(category.color),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(category.name),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
        ],
      ),
      
      body: Column(
        children: [
          // Card de Estatísticas
          if (_tasks.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.list,
                    'Total',
                    stats['total'].toString(),
                  ),
                  _buildStatItem(
                    Icons.pending_actions,
                    'Pendentes',
                    stats['pending'].toString(),
                  ),
                  _buildStatItem(
                    Icons.check_circle,
                    'Concluídas',
                    stats['completed'].toString(),
                  ),
                ],
              ),
            ),
          
          // Indicadores de Filtro Ativo
          if (_categoryFilter != null || _filter != 'all')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_filter != 'all')
                    Chip(
                      label: Text(
                        _filter == 'completed' ? 'Concluídas' : 'Pendentes',
                      ),
                      onDeleted: () => setState(() => _filter = 'all'),
                    ),
                  if (_categoryFilter != null)
                    Chip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _parseColor(_getCategoryById(_categoryFilter)?.color ?? ''),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(_getCategoryById(_categoryFilter)?.name ?? ''),
                        ],
                      ),
                      onDeleted: () => setState(() => _categoryFilter = null),
                    ),
                ],
              ),
            ),
          
          // Lista de Tarefas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTasks.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            final category = _getCategoryById(task.categoryId);
                            
                            return TaskCard(
                              task: task,
                              category: category,
                              onTap: () => _openTaskForm(task),
                              onToggle: () => _toggleTask(task),
                              onDelete: () => _deleteTask(task),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nova Tarefa'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    if (_categoryFilter != null || _filter != 'all') {
      message = 'Nenhuma tarefa encontrada com os filtros aplicados';
      icon = Icons.search_off;
    } else {
      switch (_filter) {
        case 'completed':
          message = 'Nenhuma tarefa concluída ainda';
          icon = Icons.check_circle_outline;
          break;
        case 'pending':
          message = 'Nenhuma tarefa pendente';
          icon = Icons.pending_actions;
          break;
        default:
          message = 'Nenhuma tarefa cadastrada';
          icon = Icons.task_alt;
      }
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (_categoryFilter != null || _filter != 'all')
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _filter = 'all';
                  _categoryFilter = null;
                });
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpar filtros'),
            )
          else
            TextButton.icon(
              onPressed: () => _openTaskForm(),
              icon: const Icon(Icons.add),
              label: const Text('Criar primeira tarefa'),
            ),
        ],
      ),
    );
  }

  Map<String, int> _calculateStats() {
    return {
      'total': _tasks.length,
      'completed': _tasks.where((t) => t.completed).length,
      'pending': _tasks.where((t) => !t.completed).length,
    };
  }
}
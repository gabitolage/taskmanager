import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/category.dart'; // Nova importação

class TaskCard extends StatelessWidget {
  final Task task;
  final Category? category; // Nova propriedade
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.category, // Nova propriedade
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  Color _getPriorityColor() {
    switch (task.priority) {
      case 'low': return Colors.green;
      case 'medium': return Colors.orange;
      case 'high': return Colors.red;
      case 'urgent': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _getPriorityIcon() {
    switch (task.priority) {
      case 'urgent': return Icons.priority_high;
      default: return Icons.flag;
    }
  }

  String _getPriorityLabel() {
    switch (task.priority) {
      case 'low': return 'Baixa';
      case 'medium': return 'Média';
      case 'high': return 'Alta';
      case 'urgent': return 'Urgente';
      default: return 'Média';
    }
  }

  Color _getDueDateColor() {
    if (task.dueDate == null || task.completed) return Colors.grey;
    
    if (task.isOverdue) return Colors.red;
    if (task.isDueToday) return Colors.orange;
    
    final now = DateTime.now();
    final difference = task.dueDate!.difference(now);
    if (difference.inDays <= 2) return Colors.orange;
    
    return Colors.green;
  }

  String _getDueDateText() {
    if (task.dueDate == null) return 'Sem data';
    
    final now = DateTime.now();
    final dueDate = task.dueDate!;
    final difference = dueDate.difference(now);
    
    if (task.isOverdue) {
      return 'Vencida ${DateFormat('dd/MM').format(dueDate)}';
    } else if (task.isDueToday) {
      return 'Hoje';
    } else if (difference.inDays == 1) {
      return 'Amanhã';
    } else if (difference.inDays <= 7) {
      return 'Em ${difference.inDays} dias';
    } else {
      return DateFormat('dd/MM').format(dueDate);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: task.completed ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: task.completed ? Colors.grey.shade300 : _getPriorityColor(),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Checkbox
                  Checkbox(
                    value: task.completed,
                    onChanged: (_) => onToggle(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Conteúdo Principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: task.completed ? TextDecoration.lineThrough : null,
                            color: task.completed ? Colors.grey : Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: task.completed ? Colors.grey.shade400 : Colors.grey.shade700,
                              decoration: task.completed ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        
                        const SizedBox(height: 8),
                        
                        // Metadata Row
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            // Categoria
                            if (category != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _parseColor(category!.color),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _parseColor(category!.color),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      category!.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _parseColor(category!.color),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            // Prioridade
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getPriorityColor(),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getPriorityIcon(),
                                    size: 14,
                                    color: _getPriorityColor(),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getPriorityLabel(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getPriorityColor(),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Data de Vencimento
                            if (task.dueDate != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: _getDueDateColor().withOpacity(0.1),
                                  border: Border.all(
                                    color: _getDueDateColor(),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      task.isOverdue ? Icons.warning : Icons.calendar_today,
                                      size: 14,
                                      color: _getDueDateColor(),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getDueDateText(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getDueDateColor(),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            // Data de Criação
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd/MM/yy').format(task.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Botão Deletar
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    tooltip: 'Deletar tarefa',
                  ),
                ],
              ),
            ),
          ),
          
          // Badge de vencida
          if (task.isOverdue && !task.completed)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'VENCIDA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/what_if_provider.dart';

class WhatIfAnalysisPage extends StatefulWidget {
  const WhatIfAnalysisPage({super.key});

  @override
  State<WhatIfAnalysisPage> createState() => _WhatIfAnalysisPageState();
}

class _WhatIfAnalysisPageState extends State<WhatIfAnalysisPage> {
  late TextEditingController _currentCGPAController;
  late TextEditingController _currentCreditsController;
  late TextEditingController _targetCGPAController;
  late TextEditingController _newMarksController;
  late TextEditingController _newCreditController;
  late TextEditingController _outOfController;

  String _selectedAnalysisType =
      'predictedGPA'; // predictedGPA or requiredScore

  @override
  void initState() {
    super.initState();
    _currentCGPAController = TextEditingController(text: '0.0');
    _currentCreditsController = TextEditingController(text: '12');
    _targetCGPAController = TextEditingController(text: '8.0');
    _newMarksController = TextEditingController(text: '0');
    _newCreditController = TextEditingController(text: '4');
    _outOfController = TextEditingController(text: '100');
  }

  @override
  void dispose() {
    _currentCGPAController.dispose();
    _currentCreditsController.dispose();
    _targetCGPAController.dispose();
    _newMarksController.dispose();
    _newCreditController.dispose();
    _outOfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('What-If Analysis'),
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Consumer<WhatIfAnalysisProvider>(
          builder: (context, provider, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Analysis Type Selection
                _buildAnalysisTypeSelector(),
                const SizedBox(height: 24),

                // Input fields based on selected type
                if (_selectedAnalysisType == 'predictedGPA')
                  _buildPredictedGPAInputs(context, provider)
                else
                  _buildRequiredScoreInputs(context, provider),

                const SizedBox(height: 24),

                // Result section
                if (_selectedAnalysisType == 'predictedGPA')
                  _buildPredictedGPAResult(context, provider)
                else
                  _buildRequiredScoreResult(context, provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnalysisTypeSelector() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Analysis Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AnalysisTypeButton(
                    label: 'Predicted GPA',
                    isSelected: _selectedAnalysisType == 'predictedGPA',
                    onTap: () =>
                        setState(() => _selectedAnalysisType = 'predictedGPA'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AnalysisTypeButton(
                    label: 'Required Score',
                    isSelected: _selectedAnalysisType == 'requiredScore',
                    onTap: () =>
                        setState(() => _selectedAnalysisType = 'requiredScore'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictedGPAInputs(
    BuildContext context,
    WhatIfAnalysisProvider provider,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calculate Predicted GPA',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: 'Current CGPA',
              controller: _currentCGPAController,
              hintText: 'Enter current CGPA',
            ),
            const SizedBox(height: 12),
            _buildInputField(
              label: 'Current Total Credits',
              controller: _currentCreditsController,
              hintText: 'Enter total credits',
            ),
            const SizedBox(height: 12),
            _buildInputField(
              label: 'New Subject Marks',
              controller: _newMarksController,
              hintText: 'Enter marks obtained',
            ),
            const SizedBox(height: 12),
            _buildInputField(
              label: 'New Subject Credits',
              controller: _newCreditController,
              hintText: 'Enter credit hours',
            ),
            const SizedBox(height: 12),
            _buildInputField(
              label: 'Marks Out Of',
              controller: _outOfController,
              hintText: 'Enter total marks',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequiredScoreInputs(
    BuildContext context,
    WhatIfAnalysisProvider provider,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calculate Required Score',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: 'Target CGPA',
              controller: _targetCGPAController,
              hintText: 'Enter target CGPA',
            ),
            const SizedBox(height: 12),
            _buildInputField(
              label: 'Subject Credits',
              controller: _newCreditController,
              hintText: 'Enter credit hours',
            ),
            const SizedBox(height: 12),
            _buildInputField(
              label: 'Marks Out Of',
              controller: _outOfController,
              hintText: 'Enter total marks',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictedGPAResult(
    BuildContext context,
    WhatIfAnalysisProvider provider,
  ) {
    try {
      final currentCGPA = double.tryParse(_currentCGPAController.text) ?? 0.0;
      final currentCredits =
          double.tryParse(_currentCreditsController.text) ?? 0.0;
      final newMarks = double.tryParse(_newMarksController.text) ?? 0.0;
      final newCredit = double.tryParse(_newCreditController.text) ?? 0.0;
      final outOf = double.tryParse(_outOfController.text) ?? 100.0;

      final predictedGPA = provider.calculatePredictedGPA(
        currentCGPA: currentCGPA,
        currentCredits: currentCredits,
        newMarks: newMarks,
        newCredit: newCredit,
        outOf: outOf,
      );

      final percentage = (newMarks / outOf) * 100;
      final grade = provider.getGradeFromPercentage(percentage);

      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Predicted Results',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ResultItem(
                      label: 'Predicted CGPA',
                      value: predictedGPA.toStringAsFixed(2),
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ResultItem(
                      label: 'Subject Grade',
                      value: grade,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ResultItem(
                      label: 'Percentage',
                      value: '${percentage.toStringAsFixed(1)}%',
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Please fill all fields correctly',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildRequiredScoreResult(
    BuildContext context,
    WhatIfAnalysisProvider provider,
  ) {
    try {
      final targetCGPA = double.tryParse(_targetCGPAController.text) ?? 8.0;
      final outOf = double.tryParse(_outOfController.text) ?? 100.0;

      final result = provider.calculateMinMarksNeeded(
        targetGPA: targetCGPA,
        outOf: outOf,
      );

      final marksNeeded = result['marksNeeded'] as double;
      final percentage = result['percentage'] as double;
      final grade = result['grade'] as String;

      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Required Score',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ResultItem(
                      label: 'Required Marks',
                      value: marksNeeded.toStringAsFixed(1),
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ResultItem(
                      label: 'Required Grade',
                      value: grade,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ResultItem(
                      label: 'Percentage',
                      value: '${percentage.toStringAsFixed(1)}%',
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Please fill all fields correctly',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

class _AnalysisTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnalysisTypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.blue : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _ResultItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

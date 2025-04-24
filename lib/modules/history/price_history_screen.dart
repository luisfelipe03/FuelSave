import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fuelsave/core/enum/provider_state.dart';
import 'package:fuelsave/core/models/price_record_model.dart';
import 'package:fuelsave/core/providers/history_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PriceHistoryScreen extends StatefulWidget {
  const PriceHistoryScreen({super.key});

  @override
  State<PriceHistoryScreen> createState() => _PriceHistoryScreenState();
}

class _PriceHistoryScreenState extends State<PriceHistoryScreen> {
  DateTimeRange? _selectedDateRange;
  final _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  final _ratioFormatter = NumberFormat("0.00", "pt_BR");
  final _dateFormatter = DateFormat('dd/MM/yy');
  bool _showChart = true;

  @override
  void initState() {
    super.initState();
    _loadInitialHistory();
  }

  Future<void> _loadInitialHistory() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final historyProvider = context.read<HistoryProvider>();
      if (historyProvider.state == ProviderState.Idle ||
          _selectedDateRange != null) {
        historyProvider.loadHistories(
          startDate: _selectedDateRange?.start,
          endDate: _selectedDateRange?.end,
        );
      }
    });
  }

  Future<void> _refreshHistory() async {
    if (!mounted) return;
    await context.read<HistoryProvider>().loadHistories(
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
    );
  }

  // Future<void> _showDateRangeSelector() async {
  //   final now = DateTime.now();
  //   final firstDate = DateTime(now.year - 5, now.month, now.day);
  //   final initialRange =
  //       _selectedDateRange ??
  //       DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);

  //   final DateTimeRange? picked = await showDateRangePicker(
  //     context: context,
  //     initialDateRange: initialRange,
  //     firstDate: firstDate,
  //     lastDate: now,
  //     locale: const Locale('pt', 'BR'),
  //     helpText: 'Selecione o intervalo de datas',
  //     cancelText: 'Cancelar',
  //     confirmText: 'Confirmar',
  //     builder:
  //         (context, child) => Theme(
  //           data: Theme.of(context).copyWith(
  //             colorScheme: ColorScheme.light(
  //               primary: Theme.of(context).colorScheme.primary,
  //               onPrimary: Theme.of(context).colorScheme.onPrimary,
  //               surface: Theme.of(context).colorScheme.surface,
  //               onSurface: Theme.of(context).colorScheme.onSurface,
  //             ),
  //             textButtonTheme: TextButtonThemeData(
  //               style: TextButton.styleFrom(
  //                 foregroundColor: Theme.of(context).colorScheme.primary,
  //               ),
  //             ),
  //           ),
  //           child: child!,
  //         ),
  //   );

  //   if (picked != null && picked != _selectedDateRange) {
  //     setState(() => _selectedDateRange = picked);
  //     _refreshHistory();
  //   }
  // }

  void _clearDateFilter() {
    if (_selectedDateRange != null) {
      setState(() => _selectedDateRange = null);
      _refreshHistory();
    }
  }

  void _toggleChartVisibility() {
    setState(() {
      _showChart = !_showChart;
    });
  }

  Future<void> _confirmAndDeleteRecord(
    BuildContext context,
    PriceRecordModel record,
  ) async {
    final historyProvider = context.read<HistoryProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: const Text('Confirmar Exclusão'),
            content: Text(
              'Tem certeza que deseja excluir o registro de preço de ${record.formattedDate()}?',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
              TextButton(
                child: Text(
                  'Excluir',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
            ],
          ),
    );

    if (confirm == true && record.id != null) {
      if (!context.mounted) return;
      final success = await historyProvider.deletePriceRecord(record.id!);
      if (!context.mounted) return;
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao excluir registro: ${historyProvider.errorMessage ?? 'Erro desconhecido'}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registro de preço excluído.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  Future<void> _confirmAndDeleteAllHistory(BuildContext context) async {
    final historyProvider = context.read<HistoryProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: const Text('Confirmar Exclusão Total'),
            content: const Text(
              'Tem certeza que deseja excluir TODO o histórico de preços? Esta ação não pode ser desfeita.',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
              TextButton(
                child: Text(
                  'Excluir Tudo',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
            ],
          ),
    );

    if (confirm == true) {
      if (!context.mounted) return;
      final success = await historyProvider.deleteAllPriceHistory();
      if (!context.mounted) return;
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao limpar histórico: ${historyProvider.errorMessage ?? 'Erro desconhecido'}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Histórico de preços limpo com sucesso.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Preços'),
        actions: [
          if (historyProvider.priceHistory.isNotEmpty)
            IconButton(
              icon: Icon(_showChart ? Icons.visibility_off : Icons.visibility),
              tooltip: _showChart ? 'Ocultar gráfico' : 'Mostrar gráfico',
              onPressed: _toggleChartVisibility,
            ),
          if (_selectedDateRange != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Limpar filtro de data',
              onPressed: _clearDateFilter,
            ),
          // IconButton(
          //   icon: const Icon(Icons.calendar_month),
          //   tooltip: 'Filtrar por data',
          //   onPressed:
          //       historyProvider.state == ProviderState.Loading
          //           ? null
          //           : _showDateRangeSelector,
          // ),
          if (historyProvider.priceHistory.isNotEmpty &&
              historyProvider.state != ProviderState.Loading)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Limpar todo o histórico',
              onPressed: () => _confirmAndDeleteAllHistory(context),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHistory,
        color: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        displacement: 40,
        edgeOffset: 20,
        child: CustomScrollView(
          slivers: [
            if (_selectedDateRange != null) _buildDateFilterInfo(theme),
            if (_showChart &&
                historyProvider.state != ProviderState.Error &&
                historyProvider.priceHistory.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildPriceChart(historyProvider.priceHistory, theme),
              ),
            _buildPriceContent(context, historyProvider, theme),
          ],
        ),
      ),
      floatingActionButton:
          historyProvider.priceHistory.length > 10
              ? FloatingActionButton(
                mini: true,
                child: const Icon(Icons.vertical_align_top),
                onPressed:
                    () => PrimaryScrollController.of(context).animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    ),
              )
              : null,
    );
  }

  Widget _buildDateFilterInfo(ThemeData theme) {
    final start = _dateFormatter.format(_selectedDateRange!.start);
    final end = _dateFormatter.format(_selectedDateRange!.end);
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.date_range, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Período selecionado: $start - $end',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              tooltip: 'Limpar filtro',
              onPressed: _clearDateFilter,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceChart(List<PriceRecordModel> history, ThemeData theme) {
    final reversedHistory = history.reversed.toList();
    if (reversedHistory.length < 2) return const SizedBox(height: 10);

    List<FlSpot> gasSpots = [];
    List<FlSpot> ethanolSpots = [];
    double minY = double.maxFinite;
    double maxY = double.minPositive;

    for (int i = 0; i < reversedHistory.length; i++) {
      final record = reversedHistory[i];
      final xValue = i.toDouble();
      gasSpots.add(FlSpot(xValue, record.gasolinePrice));
      ethanolSpots.add(FlSpot(xValue, record.ethanolPrice));

      if (record.gasolinePrice < minY) minY = record.gasolinePrice;
      if (record.gasolinePrice > maxY) maxY = record.gasolinePrice;
      if (record.ethanolPrice < minY) minY = record.ethanolPrice;
      if (record.ethanolPrice > maxY) maxY = record.ethanolPrice;
    }

    minY = (minY * 0.95).floorToDouble();
    maxY = (maxY * 1.05).ceilToDouble();

    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 16.0,
          right: 16.0,
          left: 6.0,
          bottom: 12.0,
        ),
        child: LineChart(
          LineChartData(
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: (maxY - minY) / 4,
              verticalInterval: (reversedHistory.length / 5).ceilToDouble(),
              getDrawingHorizontalLine:
                  (value) => FlLine(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
              getDrawingVerticalLine:
                  (value) => FlLine(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 45,
                  interval: (maxY - minY) / 4,
                  getTitlesWidget:
                      (value, meta) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          _currencyFormatter.format(value),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: (reversedHistory.length / 5).ceilToDouble(),
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < reversedHistory.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _dateFormatter.format(reversedHistory[index].date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            lineBarsData: [
              _buildLineChartBarData(gasSpots, Colors.orange, 'Gasolina'),
              _buildLineChartBarData(ethanolSpots, Colors.green, 'Etanol'),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots
                      .map((barSpot) {
                        final recordIndex = barSpot.x.toInt();
                        if (recordIndex < 0 ||
                            recordIndex >= reversedHistory.length) {
                          return null;
                        }
                        final record = reversedHistory[recordIndex];
                        final fuelName =
                            barSpot.barIndex == 0 ? 'Gasolina' : 'Etanol';
                        final price =
                            barSpot.barIndex == 0
                                ? record.gasolinePrice
                                : record.ethanolPrice;

                        return LineTooltipItem(
                          '${_dateFormatter.format(record.date)}\n',
                          theme.textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text:
                                  '$fuelName: ${_currencyFormatter.format(price)}',
                              style: TextStyle(
                                color:
                                    barSpot.bar.gradient?.colors.first ??
                                    barSpot.bar.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '\nRazão: ${_ratioFormatter.format(record.priceRatio)}',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.8,
                                ),
                              ),
                            ),
                          ],
                        );
                      })
                      .whereType<LineTooltipItem>()
                      .toList();
                },
              ),
              handleBuiltInTouches: true,
            ),
          ),
        ),
      ),
    );
  }

  LineChartBarData _buildLineChartBarData(
    List<FlSpot> spots,
    Color color,
    String label,
  ) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
      shadow: Shadow(
        color: color.withOpacity(0.3),
        blurRadius: 4,
        offset: const Offset(2, 2),
      ),
    );
  }

  Widget _buildPriceContent(
    BuildContext context,
    HistoryProvider historyProvider,
    ThemeData theme,
  ) {
    if (historyProvider.state == ProviderState.Error &&
        historyProvider.errorMessage != null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  "Erro ao carregar histórico",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  historyProvider.errorMessage!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _refreshHistory,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (historyProvider.state == ProviderState.Loading &&
        historyProvider.priceHistory.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando histórico...'),
            ],
          ),
        ),
      );
    }

    if (historyProvider.priceHistory.isEmpty &&
        historyProvider.state != ProviderState.Loading) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: theme.colorScheme.outline.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedDateRange == null
                      ? 'Nenhum preço registrado no histórico.'
                      : 'Nenhum preço encontrado para o período selecionado.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                if (_selectedDateRange != null) ...[
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _clearDateFilter,
                    child: const Text('Limpar filtro'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final record = historyProvider.priceHistory[index];
        return _buildPriceListItem(context, record, theme);
      }, childCount: historyProvider.priceHistory.length),
    );
  }

  Widget _buildPriceListItem(
    BuildContext context,
    PriceRecordModel record,
    ThemeData theme,
  ) {
    final ratio = record.priceRatio;
    Color indicatorColor = Colors.blueGrey;
    IconData indicatorIcon = Icons.compare_arrows;
    String ratioAdvice = 'Neutro';

    if (ratio <= 0.70) {
      indicatorColor = Colors.green;
      indicatorIcon = Icons.eco;
      ratioAdvice = 'Melhor Etanol';
    } else if (ratio > 0.70) {
      indicatorColor = Colors.orange;
      indicatorIcon = Icons.local_gas_station;
      ratioAdvice = 'Melhor Gasolina';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Pode adicionar ação ao clicar no item
        },
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: indicatorColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(indicatorIcon, color: indicatorColor),
              ),
              title: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: 'G: ${record.formattedGasolinePrice()}',
                      style: TextStyle(color: Colors.orange),
                    ),
                    const TextSpan(text: ' | '),
                    TextSpan(
                      text: 'E: ${record.formattedEthanolPrice()}',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.formattedDate(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Razão: ${_ratioFormatter.format(ratio)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: indicatorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ratioAdvice,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: indicatorColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                tooltip: 'Excluir registro',
                onPressed: () => _confirmAndDeleteRecord(context, record),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

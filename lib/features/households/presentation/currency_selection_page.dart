import 'package:expense_tracker/core/currency/currency_option.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class CurrencySelectionPage extends StatefulWidget {
  const CurrencySelectionPage({required this.currentCurrency, super.key});

  final String currentCurrency;

  @override
  State<CurrencySelectionPage> createState() => _CurrencySelectionPageState();
}

class _CurrencySelectionPageState extends State<CurrencySelectionPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.toLowerCase();
    final matches = supportedCurrencies.where((currency) {
      return currency.code.toLowerCase().contains(query) ||
          currency.country.toLowerCase().contains(query) ||
          currency.name.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Currency')),
      body: SafeArea(
        bottom: false,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
          itemCount: matches.length + 1,
          separatorBuilder: (_, index) =>
              SizedBox(height: index == 0 ? 20 : 11),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Currency',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose the currency Trace should use for your shared household.',
                    style: TextStyle(color: context.traceMuted, height: 1.4),
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value.trim()),
                    decoration: const InputDecoration(
                      hintText: 'Search currency, country, or code',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ],
              );
            }
            final currency = matches[index - 1];
            final selected = currency.code == widget.currentCurrency;
            return Card(
              margin: EdgeInsets.zero,
              child: InkWell(
                onTap: () => Navigator.pop(context, currency.code),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Text(currency.flag, style: const TextStyle(fontSize: 27)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currency.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currency.detail,
                              style: TextStyle(color: context.traceMuted),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.gold,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shiftsmart/models/company.dart';
import 'package:shiftsmart/screens/manager/manager_create_com.dart';
import 'package:shiftsmart/services/company_service.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/search.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';

class Managercomapny extends StatefulWidget {
  const Managercomapny({super.key});

  @override
  State<Managercomapny> createState() => _ManagercomapnyState();
}

class _ManagercomapnyState extends State<Managercomapny> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  // State Variables
  List<Company> allCom = [];
  List<Company> filteredCom = [];
  bool _isLoading = true;

  // Services
  final CompanyService _companyService = CompanyService();

  @override
  void initState() {
    super.initState();
    enableFullScreen();
    // Load data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshKey.currentState?.show();
      _refreshData();
    });
  }

  // --- 1. REFRESH LOGIC ---
  Future<void> _refreshData() async {
    if (mounted) setState(() => _isLoading = true);
    await fetchCompanies();
  }

  // --- 2. FETCH DATA ---
  Future<void> fetchCompanies() async {
    try {
      final allCompanies = await _companyService.fetchCompanies();

      if (!mounted) return;

      setState(() {
        allCom = allCompanies;
        filteredCom = allCompanies;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching companies: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 3. SEARCH LOGIC ---
  void onQueryChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCom = List.from(allCom);
      } else {
        filteredCom = allCom
            .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // --- 4. NAVIGATION HANDLER ---
  // Navigate to create/edit screen and refresh list on return
  Future<void> _navigateAndRefresh(Widget screen) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );

    // If result is true (meaning a company was added/edited), refresh list
    if (result == true) {
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: const Sidenav(),
      backgroundColor: const Color(0xFF1C2230),
      appBar: const Uppernavbar(
        showBackButton: true,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: Background()),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF724584)),
                )
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        key: _refreshKey,
                        onRefresh: _refreshData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              Search(onQueryChanged: onQueryChanged),

                              // Create Button Header
                              _createCompany(),

                              const SizedBox(height: 20),

                              // List Container
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color.fromARGB(180, 42, 50, 67),
                                      Color.fromARGB(180, 34, 40, 52),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "COMPANY LIST",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _companyList(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                )
        ],
      ),
    );
  }

  // Widget: Create Company Button Area
  Widget _createCompany() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(180, 42, 50, 67),
            Color.fromARGB(180, 34, 40, 52),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Row(
          children: [
            Icon(Icons.business_outlined, color: Color(0xFF3498DB), size: 28),
            SizedBox(width: 12),
            Text(
              "CREATE COMPANY",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => _navigateAndRefresh(const Managercreatecom()),
          child: const Icon(
            Icons.add_box_outlined,
            color: Colors.blueAccent,
            size: 32,
          ),
        ),
      ]),
    );
  }

  // Widget: List of Companies
  Widget _companyList() {
    if (filteredCom.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text("No companies found.",
              style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredCom.length,
      itemBuilder: (context, index) {
        final company = filteredCom[index];

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF363E51), Color(0xFF191E26)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Icon(Icons.business, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                if (company.address.isNotEmpty)
                  Text(
                    company.address,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            )),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () =>
                  _navigateAndRefresh(Managercreatecom(company: company)),
            ),
          ]),
        );
      },
    );
  }
}

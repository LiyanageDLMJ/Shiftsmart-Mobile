// import 'package:flutter/material.dart';
// import 'package:shiftsmart/models/project.dart';
// import 'package:shiftsmart/models/site.dart';
// import 'package:shiftsmart/screens/manager/manager_create_site.dart';
// import 'package:shiftsmart/services/project_service.dart';
// import 'package:shiftsmart/services/site_service.dart';
// import 'package:shiftsmart/utils/fullscreen_helper.dart';
// import 'package:shiftsmart/widgets/background.dart';
// import 'package:shiftsmart/widgets/search.dart';
// import 'package:shiftsmart/widgets/sidenav.dart';
// import 'package:shiftsmart/widgets/uppernavbar.dart';

// class Managersite extends StatefulWidget {
//   const Managersite({super.key});

//   @override
//   State<Managersite> createState() => _ManagersiteState();
// }

// class _ManagersiteState extends State<Managersite> {
//   final GlobalKey<RefreshIndicatorState> _refreshKey =
//       GlobalKey<RefreshIndicatorState>();
//   List<Project> activeProjects = [];
//   final ProjectService _projectService = ProjectService();
//   final SiteService _siteService = SiteService();

//   List<Site> allSites = [];
//   List<Site> filteredSites = [];
//   bool _isLoading = true;

//   void onQueryChanged(String query) {
//     setState(() {
//       if (query.isEmpty) {
//         filteredSites = List.from(allSites);
//       } else {
//         filteredSites = allSites.where((site) {
//           bool matches =
//               site.siteName.toLowerCase().contains(query.toLowerCase());
//           print(
//               "Checking: ${site.siteName} | Query: $query | Matches: $matches");
//           return matches;
//         }).toList();
//       }
//     });
//     debugPrint("Filtered Sites: $filteredSites");
//   }

//   @override
//   void initState() {
//     super.initState();
//     enableFullScreen();
//     fetchActiveProjectSites();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _refreshKey.currentState?.show(); // optional spinner
//       _refreshData();
//     });
//   }

//   Future<void> _refreshData() async {
//     setState(() => _isLoading = true);
//     await fetchActiveProjectSites();

//     // if you want to show current shift too
//     setState(() => _isLoading = false);
//   }

//   Future<void> fetchActiveProjectSites() async {
//     try {
//       // Step 1: Fetch all projects
//       final projects = await _projectService.fetchAllProjects();
//       // final List<dynamic> projectData = jsonDecode(projectResponse.body);
//       activeProjects =
//           projects.where((p) => p.status.toLowerCase() == "active").toList();

//       // Step 2: Fetch all sites
//       final sites = await _siteService.fetchAllSites();
//       allSites = sites;

//       // Step 3: Filter sites for active projects only
//       final activeProjectIds = activeProjects.map((p) => p.projectId).toSet();
//       filteredSites = allSites
//           .where((site) => activeProjectIds.contains(site.projectId))
//           .toList();

//       setState(() => _isLoading = false);
//     } catch (e) {
//       print("Error fetching data: $e");
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       drawer: const Sidenav(),
//       backgroundColor: const Color(0xFF1C2230),
//       appBar: const Uppernavbar(
//         showBackButton: true,
//       ),
//       body: Stack(
//         children: [
//           const Positioned.fill(child: Background()),
//           _isLoading
//               ? const Center(
//                   child: CircularProgressIndicator(color: Color(0xFF724584)),
//                 )
//               : Column(
//                   children: [
//                     Expanded(
//                       child: RefreshIndicator(
//                         key: _refreshKey,
//                         onRefresh: _refreshData,
//                         child: SingleChildScrollView(
//                           padding: const EdgeInsets.symmetric(horizontal: 20),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Search(onQueryChanged: onQueryChanged),

//                               _createSite(),
//                               const SizedBox(height: 20),
//                               // Task list section with gradient background
//                               Container(
//                                 decoration: BoxDecoration(
//                                   gradient: const LinearGradient(
//                                     begin: Alignment.topCenter,
//                                     end: Alignment.bottomCenter,
//                                     colors: [
//                                       Color.fromARGB(180, 42, 50, 67),
//                                       Color.fromARGB(180, 34, 40, 52),
//                                     ],
//                                   ),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 padding: const EdgeInsets.all(16),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     const Text(
//                                       "SITE LIST",
//                                       style: TextStyle(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold,
//                                         color: Colors.white,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 10),
//                                     _taskList(),
//                                   ],
//                                 ),
//                               ),
//                               const SizedBox(height: 10),
//                             ],
//                           ),
//                         ),
//                       ),
//                     )
//                   ],
//                 )
//         ],
//       ),
//     );
//   }

//   Widget _createSite() {
//     return Container(
//       margin: const EdgeInsets.only(top: 20),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             Color.fromARGB(180, 42, 50, 67),
//             Color.fromARGB(180, 34, 40, 52),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//         const Row(
//           children: [
//             Icon(
//               Icons.travel_explore,
//               color: Color(0xFF3498DB),
//               size: 28,
//             ),
//             SizedBox(width: 12),
//             Text(
//               "CREATE SITE",
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//         GestureDetector(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                   builder: (context) => const Managercreatesite()),
//             );
//           },
//           child: Icon(
//             Icons.add_box_outlined,
//             color: Colors.blueAccent,
//             size: 32,
//           ),
//         ),
//       ]),
//     );
//   }

//   Widget _taskList() {
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: filteredSites.length,
//       itemBuilder: (context, index) {
//         final site = filteredSites[index];

//         return InkWell(
//           onTap: () {
//             // Navigate if needed
//           },
//           child: Container(
//             margin: const EdgeInsets.symmetric(vertical: 6),
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [Color(0xFF363E51), Color(0xFF191E26)],
//               ),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Row(children: [
//               const Icon(Icons.location_on, color: Colors.white, size: 24),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       site.siteName,
//                       style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       site.project?.name ?? 'No Project Name',
//                       style: TextStyle(
//                         color: Colors.grey[400],
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 25),
//               IconButton(
//                 icon: const Icon(
//                   Icons.edit,
//                   color: Colors.white,
//                   size: 24,
//                 ),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) =>
//                           Managercreatesite(site: site), //  pass the site
//                     ),
//                   );
//                 },
//               ),
//             ]),
//           ),
//         );
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shiftsmart/providers/tenant_provider.dart';
import 'package:shiftsmart/models/project.dart';
import 'package:shiftsmart/models/site.dart';
import 'package:shiftsmart/screens/manager/manager_create_site.dart';
import 'package:shiftsmart/services/project_service.dart';
import 'package:shiftsmart/services/site_service.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/search.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';

class Managersite extends StatefulWidget {
  const Managersite({super.key});

  @override
  State<Managersite> createState() => _ManagersiteState();
}

class _ManagersiteState extends State<Managersite> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();
  List<Project> activeProjects = [];
  final ProjectService _projectService = ProjectService();
  final SiteService _siteService = SiteService();

  List<Site> allSites = [];
  List<Site> filteredSites = [];
  bool _isLoading = true;
  String _lastTenant = '';

  void onQueryChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredSites = List.from(allSites);
      } else {
        filteredSites = allSites.where((site) {
          bool matches =
              site.siteName.toLowerCase().contains(query.toLowerCase());
          return matches;
        }).toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    enableFullScreen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshKey.currentState?.show();
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    // Prevent infinite loading loop if already loading
    // setState(() => _isLoading = true);
    await fetchActiveProjectSites();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> fetchActiveProjectSites() async {
    try {
      // Step 1: Fetch all projects
      final projects = await _projectService.fetchAllProjects();

      //  FIX: Don't filter out completed projects yet, or allow both.
      // For now, let's keep ALL projects so you can see your new site.
      activeProjects = projects;

      // If you really only want Active, use this instead:
      // activeProjects = projects.where((p) =>
      //    p.status.toLowerCase() == "active" ||
      //    p.status.toLowerCase() == "completed" // Include Completed too?
      // ).toList();

      // Step 2: Fetch all sites
      final sites = await _siteService.fetchAllSites();
      allSites = sites;

      // Step 3: Filter sites based on the projects we kept
      final projectIdsToCheck = activeProjects.map((p) => p.projectId).toSet();

      filteredSites = allSites
          .where((site) => projectIdsToCheck.contains(site.projectId))
          .toList();

      debugPrint(" Total Projects: ${projects.length}");
      debugPrint(" Total Sites: ${allSites.length}");
      debugPrint(" Visible Sites: ${filteredSites.length}");

      setState(() => _isLoading = false);
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TenantProvider>(
      builder: (context, tp, _) {
        if (tp.selectedOrganization != _lastTenant) {
          _lastTenant = tp.selectedOrganization;
          if (_lastTenant.isNotEmpty && mounted && !_isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
          }
        }
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
                      child:
                          CircularProgressIndicator(color: Color(0xFF724584)),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            key: _refreshKey,
                            onRefresh: _refreshData,
                            child: SingleChildScrollView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Search(onQueryChanged: onQueryChanged),
                                  _createSite(),
                                  const SizedBox(height: 20),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "SITE LIST",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        _taskList(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
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
      },
    );
  }

  Widget _createSite() {
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
            Icon(
              Icons.travel_explore,
              color: Color(0xFF3498DB),
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              "CREATE SITE",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        GestureDetector(
          //  KEY FIX: Wait for result and refresh
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const Managercreatesite()),
            );

            // If we come back with 'true', refresh the list!
            if (result == true) {
              debugPrint(" Refreshing Site List...");
              _refreshKey.currentState?.show();
              _refreshData();
            }
          },
          child: const Icon(
            Icons.add_box_outlined,
            color: Colors.blueAccent,
            size: 32,
          ),
        ),
      ]),
    );
  }

  Widget _taskList() {
    if (filteredSites.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child:
              Text("No sites found.", style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredSites.length,
      itemBuilder: (context, index) {
        final site = filteredSites[index];

        return InkWell(
          onTap: () {
            // Navigate if needed
          },
          child: Container(
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
              const Icon(Icons.location_on, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site.siteName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      site.project?.name ?? 'No Project Name',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 25),
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () async {
                  //  KEY FIX: Refresh on Update too
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Managercreatesite(site: site),
                    ),
                  );

                  if (result == true) {
                    _refreshData();
                  }
                },
              ),
            ]),
          ),
        );
      },
    );
  }
}

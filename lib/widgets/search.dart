import 'package:flutter/material.dart';

class Search extends StatefulWidget {
  final void Function(String query) onQueryChanged;
  const Search({super.key, required this.onQueryChanged});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {}); // Rebuild when text changes
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _controller.clear(); // Triggers listener  setState  rebuild
    widget.onQueryChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        onChanged: widget.onQueryChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: const TextStyle(color: Colors.white),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: _clearSearch,
                )
              : null,
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
        ),
      ),
    );
  }
}

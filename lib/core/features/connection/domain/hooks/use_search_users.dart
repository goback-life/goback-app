import 'package:cloudless/core/features/connection/domain/models/connection_request_model.dart';
import 'package:cloudless/core/features/connection/domain/providers/search_users_provider.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

typedef SearchUserResult = (ProfileModel, ConnectionStatus);

class SearchUsersData {
  const SearchUsersData({
    required this.results,
    required this.isLoading,
    required this.query,
    required this.updateQuery,
  });

  final List<SearchUserResult> results;
  final bool isLoading;
  final String query;
  final void Function(String) updateQuery;
}

SearchUsersData useSearchUsers(WidgetRef ref) {
  final query = useState<String>('');
  final trimmed = query.value.trim();

  final asyncResults = trimmed.isNotEmpty
      ? ref.watch(searchUsersProvider(trimmed))
      : null;

  final results = useMemoized(() {
    if (asyncResults == null) return <SearchUserResult>[];
    return asyncResults.when(
      data: (result) => result.fold(
        (list) => list,
        (_) => <SearchUserResult>[],
      ),
      loading: () => <SearchUserResult>[],
      error: (_, __) => <SearchUserResult>[],
    );
  }, [asyncResults]);

  final isLoading = asyncResults != null && asyncResults.isLoading;

  return SearchUsersData(
    results: results,
    isLoading: isLoading,
    query: query.value,
    updateQuery: (q) => query.value = q,
  );
}

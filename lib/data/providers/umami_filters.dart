import '../models/indicator.dart';

/// Paramètres `epf<N>` d'Umami pour des filtres de propriétés d'événement :
/// `<type>.<op>.<nom encodé>.<valeur>`, combinés en ET.
///
/// Le nom est encodé puis ses points sont échappés, sinon le `.` d'une
/// propriété (`niveau.max`) serait pris pour un séparateur. La valeur reste
/// brute : c'est le dernier champ, Umami n'en découpe que les trois premiers.
Map<String, String> umamiEventFilterParams(List<EventFilter> filters) => {
      for (var i = 0; i < filters.length; i++)
        'epf$i': '${filters[i].type.code}.${filters[i].op.api}.'
            '${Uri.encodeComponent(filters[i].property).replaceAll('.', '%2E')}.'
            '${filters[i].value}',
    };

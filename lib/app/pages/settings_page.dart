import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dart_ipify/dart_ipify.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/cubits.dart';
import '../custom_widgets/custom_widgets.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../utils/utils.dart';
import 'pages.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.repositoriesCubit,
    required this.onRepositorySelect,
    required this.onShareRepository,
    required this.connectivitySubscription,
    required this.title,
    this.dhtStatus = false, 
  });

  final RepositoriesCubit repositoriesCubit;
  final RepositoryCallback onRepositorySelect;
  final void Function() onShareRepository;
  final StreamSubscription<ConnectivityResult>? connectivitySubscription;
  final String title;
  final bool dhtStatus;

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  RepositoriesService _repositoriesSession = RepositoriesService();

  PersistedRepository? _persistedRepository;
  String? _localEndpoint;
  bool _bittorrentDhtStatus = false;

  Color? _titlesColor = Colors.black;


  @override
  void initState() {
    super.initState();
 
    _getLocalEndpoint();

    _bittorrentDhtStatus = widget.dhtStatus;
    print('BitTorrent DHT status: ${widget.dhtStatus}');

    setState(() {
      _persistedRepository = _repositoriesSession.current;
    });
  }

  void _getLocalEndpoint() async {
    final connectivity = await Connectivity().checkConnectivity();
    final isConnected = [
      ConnectivityResult.ethernet,
      ConnectivityResult.mobile,
      ConnectivityResult.wifi
    ].contains(connectivity);

    _getConnectivityInfo(isConnected)
    .then((localEndpoint) => 
      setState(() => _localEndpoint = localEndpoint)
    );
  }

  Future<String> _getConnectivityInfo(bool connected) async {
    String localEndpoint = widget.repositoriesCubit.session
    .local_network_address();

    if (!connected) {
      return localEndpoint;
    }

    if (localEndpoint.contains(Strings.emptyIPv4) ||
    localEndpoint.contains(Strings.undeterminedIPv6)) { 
      try {
        final iPv64 = await Ipify.ipv64();
        localEndpoint = iPv64;  
      } catch (e) {
        print('error getting the IP address: $e');
      }
    }

    return localEndpoint;
  }

  @override
  Widget build(BuildContext context) {
    _titlesColor = Theme.of(context).colorScheme.secondaryVariant;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRepositoriesSection(),
            const Divider(
              height: 20.0,
              thickness: 1.0,
            ),
            Fields.idLabel(Strings.titleNetwork,
              fontSize: Dimensions.fontAverage,
              fontWeight: FontWeight.normal,
              color: _titlesColor!
            ),
            LabeledSwitch(
              label: Strings.labelBitTorrentDHT,
              padding: const EdgeInsets.all(0.0),
              value: _bittorrentDhtStatus,
              onChanged: updateDhtSetting,
            ),
            BlocConsumer<ConnectivityCubit, ConnectivityState>(
              builder: (context, state) {
                return Fields.labeledText(
                  label: Strings.labelLocalEndpoint,
                  text: _localEndpoint ?? Strings.statusUnspecified,
                  labelTextAlign: TextAlign.start
                );
              },
              listener: (context, state) {
                if (state is ConnectivityChanged) {
                  _getLocalEndpoint();
                }
              }
            ),
          ],
        )
      )
    );
  }

  Widget _buildRepositoriesSection() {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Fields.idLabel(Strings.titleRepository,
            fontSize: Dimensions.fontAverage,
            fontWeight: FontWeight.normal,
            color: _titlesColor!
          ),
          Dimensions.spacingVertical,
          Container(
            decoration: BoxDecoration(
              borderRadius : BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(0),
              ),
              color : Color.fromRGBO(33, 33, 33, 0.07999999821186066),
            ),
            child: Container(
              padding: Dimensions.paddingActionBox,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(Dimensions.radiusMicro)),
                border: Border.all(
                  color: Colors.black45,
                  width: 1.0,
                  style: BorderStyle.solid
                ),
                color: Colors.grey.shade300,
              ),
              child: BlocConsumer(
                bloc: widget.repositoriesCubit,
                builder: (context, state) {
                  if (state is RepositoryPickerSelection) {
                    return DropdownButton(
                      isExpanded: true,
                      value: _persistedRepository,
                      underline: SizedBox(),
                      items: _repositoriesSession.repositories.map((PersistedRepository persisted) {
                        return DropdownMenuItem(
                          value: persisted,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Fields.idLabel(
                                Strings.labelSelectRepository,
                                textAlign: TextAlign.start,
                                fontWeight: FontWeight.normal,
                                color: Colors.grey.shade600
                              ),
                              Dimensions.spacingVerticalHalf,
                              Row(
                                children: [
                                  Fields.constrainedText(
                                    persisted.name,
                                    fontWeight: FontWeight.normal
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (persisted) async {
                        print('Selected: $persisted');
                        
                        setState(() {
                          _persistedRepository = persisted as PersistedRepository;
                        });
                      },
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Fields.idLabel(
                        Strings.labelSelectRepository,
                        textAlign: TextAlign.start,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade600
                      ),
                      Dimensions.spacingVerticalHalf,
                      Row(
                        children: [
                          Fields.constrainedText(
                            Strings.messageNoRepos,
                            fontWeight: FontWeight.normal
                          ),
                        ],
                      ),
                    ],
                  );
                },
                listener: (context, state) {
                  if (state is RepositoryPickerSelection) {
                    setState(() {
                      _persistedRepository = _repositoriesSession.current!;
                    });
                  }
                },
              ),
            ),
          ),
          Dimensions.spacingVertical,
          Row(
            children: [
              Expanded(
                child: Fields.actionText(
                  Strings.actionEdit,
                  textFontSize: Dimensions.fontAverage,
                  icon: Icons.edit,
                  iconSize: Dimensions.sizeIconSmall,
                  spacing: Dimensions.spacingHorizontalHalf,
                  onTap: () async {
                    if (!_repositoriesSession.hasCurrent) {
                      return;
                    }

                    await showDialog<String>(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        final formKey = GlobalKey<FormState>();

                        return ActionsDialog(
                          title: Strings.messageRenameRepository,
                          body: RenameRepository(
                            context: context,
                            formKey: formKey,
                            repositoryName: _repositoriesSession.current!.name
                          ),
                        );
                      }
                    ).then((newName) {
                      if (newName?.isNotEmpty ?? false) {
                        widget.repositoriesCubit
                        .renameRepository(_repositoriesSession.current!.name, newName!);
                      }
                    });
                  }
                ),
              ),
              Expanded(
                child: Fields.actionText(
                  Strings.actionShare,
                  textFontSize: Dimensions.fontAverage,
                  icon: Icons.share,
                  iconSize: Dimensions.sizeIconSmall,
                  spacing: Dimensions.spacingHorizontalHalf,
                  onTap: () {
                    if (!_repositoriesSession.hasCurrent) {
                      return;
                    }

                    widget.onShareRepository.call();
                  }
                )
              ),
              Expanded(
                child: Fields.actionText(
                  Strings.actionDelete,
                  textFontSize: Dimensions.fontAverage,
                  textColor: Colors.red,
                  icon: Icons.delete,
                  iconSize: Dimensions.sizeIconSmall,
                  iconColor: Colors.red,
                  spacing: Dimensions.spacingHorizontalHalf,
                  onTap: () async {
                    if (!_repositoriesSession.hasCurrent) {
                      return;
                    }
                    await showDialog<bool>(
                      context: context,
                      barrierDismissible: false, // user must tap button!
                      builder: (context) {
                        return AlertDialog(
                          title: Text(Strings.titleDeleteRepository),
                          content: SingleChildScrollView(
                            child: ListBody(children: [
                              Text(Strings.messageConfirmRepositoryDeletion)
                            ]),
                          ),
                          actions: [
                            TextButton(
                              child: const Text(Strings.actionDeleteCapital),
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              }
                            ),
                            TextButton(
                              child: const Text(Strings.actionCloseCapital),
                              onPressed: () => 
                              Navigator.of(context).pop(false),
                            )
                          ],
                        );
                    }).then((delete) {
                      if (delete ?? false) {
                        widget.repositoriesCubit
                        .deleteRepository(_repositoriesSession.current?.name ?? '');
                      }
                    });
                  }
                )
              )
            ],
          ),
        ]
    );
  }

  Future<void> updateDhtSetting(bool enable) async {
    if (!_repositoriesSession.hasCurrent) {
      return;
    }

    print('${enable ? 'Enabling': 'Disabling'} BitTorrent DHT...');

    enable ? await _repositoriesSession.current!.repository.enableDht()
    : await _repositoriesSession.current!.repository.disableDht();
    
    final isEnabled = await _repositoriesSession.current!.repository.isDhtEnabled();
    setState(() {
      _bittorrentDhtStatus = isEnabled;
    });

    String dhtStatusMessage = Strings.messageBitTorrentDHTStatus
    .replaceAll(
      Strings.replacementStatus,
      isEnabled ? 'enabled' : 'disabled'
    );
    if (enable != isEnabled) {
      dhtStatusMessage = enable ? Strings.messageBitTorrentDHTEnableFailed
      : Strings.messageBitTorrentDHTDisableFailed;
    }

    print(dhtStatusMessage);
    showToast(dhtStatusMessage);
  }
}
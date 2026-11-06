import 'package:dartz/dartz.dart';
import 'package:flutter_almightyflippa/core/api/network_result.dart';
import 'package:flutter_almightyflippa/core/common/models/network_failure.dart';
import 'package:flutter_almightyflippa/core/common/models/network_success.dart';
import 'package:flutter_almightyflippa/features/auth/controller/tv_login_approve_controller.dart';
import 'package:flutter_almightyflippa/features/auth/controller/tv_qr_login_controller.dart';
import 'package:flutter_almightyflippa/features/auth/models/login_response_model.dart';
import 'package:flutter_almightyflippa/features/auth/models/tv_login_models.dart';
import 'package:flutter_almightyflippa/features/auth/repo/auth_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

NetworkSuccess<T> ok<T>(T data) =>
    NetworkSuccess<T>(data: data, message: '', statusCode: 200);

class _FakeRepo implements AuthRepo {
  final codes = <TvLoginCode>[];
  final polls = <Either<NetworkFailure, NetworkSuccess<TvLoginPollResult>>>[];
  Either<NetworkFailure, NetworkSuccess<void>> approveResult = Right(
    ok<void>(null),
  );

  int codeRequests = 0;
  final polledWith = <String>[];
  final approved = <String>[];

  @override
  NetworkResult<TvLoginCode> requestTvLoginCode({
    required String deviceId,
    required String deviceName,
  }) async {
    final c = codes[codeRequests.clamp(0, codes.length - 1)];
    codeRequests++;
    return Right(ok(c));
  }

  @override
  NetworkResult<TvLoginPollResult> pollTvLogin(String deviceCode) async {
    polledWith.add(deviceCode);
    if (polls.isEmpty) {
      return Right(
        ok(const TvLoginPollResult(status: TvLoginStatus.pending)),
      );
    }
    return polls.removeAt(0);
  }

  @override
  NetworkResult<void> approveTvLogin({
    required String userCode,
    required bool approve,
  }) async {
    approved.add(userCode);
    return approveResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TvLoginCode code(String device, String user) => TvLoginCode(
  deviceCode: device,
  userCode: user,
  expiresIn: const Duration(minutes: 10),
  interval: const Duration(seconds: 2),
);

void main() {
  group('TvLoginCodeFormat', () {
    test('normalize accepts dashes, spaces and lower case', () {
      expect(TvLoginCodeFormat.normalize('bcdf-ghjk'), 'BCDFGHJK');
      expect(TvLoginCodeFormat.normalize(' BCDF GHJK '), 'BCDFGHJK');
    });

    test('normalize rejects wrong length and look-alike characters', () {
      expect(TvLoginCodeFormat.normalize('BCDFGHJ'), isNull);
      expect(TvLoginCodeFormat.normalize('BCDFGHJKM'), isNull);
      // O, 0, I, 1 and vowels are not in the alphabet.
      expect(TvLoginCodeFormat.normalize('BCDFGHJO'), isNull);
      expect(TvLoginCodeFormat.normalize('BCDFGHJ0'), isNull);
      expect(TvLoginCodeFormat.normalize('BCDFGHJA'), isNull);
    });

    test('display splits the code in two', () {
      expect(TvLoginCodeFormat.display('BCDFGHJK'), 'BCDF-GHJK');
    });

    test('parseScanned reads our QR link or a bare code', () {
      final payload = TvLoginCodeFormat.qrPayload('BCDFGHJK');
      expect(TvLoginCodeFormat.parseScanned(payload), 'BCDFGHJK');
      expect(TvLoginCodeFormat.parseScanned('bcdf-ghjk'), 'BCDFGHJK');
    });

    test('parseScanned ignores other QR codes', () {
      expect(TvLoginCodeFormat.parseScanned('https://example.com'), isNull);
      expect(
        TvLoginCodeFormat.parseScanned('labbytv://other?code=BCDFGHJK'),
        isNull,
      );
      expect(TvLoginCodeFormat.parseScanned('labbytv://tv-login'), isNull);
    });
  });

  group('models', () {
    test('TvLoginCode parses seconds and clamps the poll interval', () {
      final c = TvLoginCode.fromJson({
        'deviceCode': 'd',
        'userCode': 'BCDFGHJK',
        'expiresIn': 600,
        'interval': 0,
      });
      expect(c.expiresIn, const Duration(minutes: 10));
      expect(c.interval, const Duration(seconds: 2));
    });

    test('approved poll carries the login tokens', () {
      final r = TvLoginPollResult.fromJson({
        'status': 'approved',
        'accessToken': 'a',
        'refreshToken': 'r',
        'role': 'user',
        '_id': 'u1',
      });
      expect(r.status, TvLoginStatus.approved);
      expect(r.login?.accessToken, 'a');
      expect(r.login?.id, 'u1');
    });

    test('approved without tokens is treated as pending', () {
      final r = TvLoginPollResult.fromJson({'status': 'approved'});
      expect(r.status, TvLoginStatus.pending);
      expect(r.login, isNull);
    });

    test('unknown status is pending', () {
      expect(
        TvLoginPollResult.fromJson({'status': 'weird'}).status,
        TvLoginStatus.pending,
      );
    });
  });

  group('TvQrLoginController', () {
    late _FakeRepo repo;
    LoginData? signedIn;

    TvQrLoginController make() => TvQrLoginController(
      repo: repo,
      deviceId: () async => 'tv-1',
      onSignedIn: (d) async => signedIn = d,
    );

    setUp(() {
      Get.testMode = true;
      repo = _FakeRepo()..codes.addAll([code('d1', 'BCDFGHJK')]);
      signedIn = null;
    });

    test('shows the code, then signs in when the phone approves', () async {
      repo.polls.add(
        Right(ok(const TvLoginPollResult(status: TvLoginStatus.pending))),
      );
      repo.polls.add(
        Right(
          ok(
            TvLoginPollResult(
              status: TvLoginStatus.approved,
              login: LoginData(accessToken: 'a', refreshToken: 'r', id: 'u1'),
            ),
          ),
        ),
      );

      final c = make();
      c.onInit();
      await Future<void>.delayed(Duration.zero);
      expect(c.state.value, TvQrLoginState.showingCode);
      expect(c.code.value?.userCode, 'BCDFGHJK');

      await Future<void>.delayed(const Duration(milliseconds: 4200));
      expect(repo.polledWith, ['d1', 'd1']);
      expect(c.state.value, TvQrLoginState.signingIn);
      expect(signedIn?.accessToken, 'a');

      // Polling stops after sign-in.
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      expect(repo.polledWith.length, 2);
      c.onClose();
    });

    test('denied or expired gets a new code', () async {
      repo.codes.add(code('d2', 'MNPQRTVW'));
      repo.polls.add(
        Right(ok(const TvLoginPollResult(status: TvLoginStatus.denied))),
      );

      final c = make();
      c.onInit();
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      expect(c.deniedNotice.value, isTrue);
      expect(repo.codeRequests, 2);
      expect(c.code.value?.deviceCode, 'd2');
      c.onClose();
    });

    test('unknown device code (404) gets a new code; 500 keeps polling',
        () async {
      repo.codes.add(code('d2', 'MNPQRTVW'));
      repo.polls.add(
        const Left(ServerFailure(message: 'oops', statusCode: 500)),
      );
      repo.polls.add(
        const Left(ServerFailure(message: 'gone', statusCode: 404)),
      );

      final c = make();
      c.onInit();
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      expect(repo.codeRequests, 1);
      await Future<void>.delayed(const Duration(milliseconds: 2100));
      expect(repo.codeRequests, 2);
      expect(c.code.value?.deviceCode, 'd2');
      c.onClose();
    });

    test('a missing backend endpoint shows a clear message', () async {
      final missing = _MissingEndpointRepo();
      final c = TvQrLoginController(
        repo: missing,
        deviceId: () async => 'tv-1',
        onSignedIn: (_) async {},
      );
      c.onInit();
      await Future<void>.delayed(Duration.zero);
      expect(c.state.value, TvQrLoginState.error);
      expect(c.errorMessage.value, contains('not available yet'));
      c.onClose();
    });
  });

  group('TvLoginApproveController', () {
    late _FakeRepo repo;
    setUp(() {
      Get.testMode = true;
      repo = _FakeRepo();
    });

    test('approves a normalized code', () async {
      final c = TvLoginApproveController(repo: repo);
      expect(await c.approve('bcdf-ghjk'), isTrue);
      expect(repo.approved, ['BCDFGHJK']);
      expect(c.errorMessage.value, isEmpty);
    });

    test('rejects a malformed code without calling the server', () async {
      final c = TvLoginApproveController(repo: repo);
      expect(await c.approve('abc'), isFalse);
      expect(repo.approved, isEmpty);
      expect(c.errorMessage.value, isNotEmpty);
    });

    test('expired code shows a helpful message', () async {
      repo.approveResult = const Left(
        ServerFailure(message: 'not found', statusCode: 404),
      );
      final c = TvLoginApproveController(repo: repo);
      expect(await c.approve('BCDFGHJK'), isFalse);
      expect(c.errorMessage.value, contains('expired'));
    });
  });
}

class _MissingEndpointRepo extends _FakeRepo {
  @override
  NetworkResult<TvLoginCode> requestTvLoginCode({
    required String deviceId,
    required String deviceName,
  }) async => const Left(ServerFailure(message: 'Not found', statusCode: 404));
}

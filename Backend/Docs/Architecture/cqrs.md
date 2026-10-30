# Request flow (CQRS)

Controller → `IMediator.Send` → pipeline → handler.

- Requests implement `ICommand<T>` (changes state) or `IQuery<T>` (reads), in
  `PAO.Lib/Mediator`. One handler (`IRequestHandler<TRequest,TResult>`) per use case,
  in `Areas/<Area>/Features/<Feature>/Commands|Queries/` with its request and validator.
- The in-house `Mediator` (`PAO.Infrastructure/Mediation`) replaces MediatR, whose licence
  is commercial. The pipeline, outermost first: `LoggingBehavior` (debug timing, warning on
  failure) → `ValidationBehavior` (FluentValidation; first failure becomes 422
  `VALIDATION_FAILED` with `details.field` and `details.reason`) → `TransactionBehavior`
  (commands run in one database transaction; nested commands join it; queries never open one).
- Models stay separate: request models in, view models out, db models in `PAO.EF`. The
  hand-written `Mapper` converts with maps registered by `IMappingProfile` classes; a
  missing map throws instead of guessing. Profiles live in `PAO.Lib/Areas/<Area>/` and
  `AddMediator` always scans PAO.Lib for them, so an area never registers its profile by
  hand; the `MappingProfileTests` gate fails if any PAO.Lib profile is not registered
  exactly once.
- No N+1: repositories load related rows with `BatchLoader.LoadMany` (one `ANY(@ids)`
  query) and small reference data through `ReferenceDataCache`.

# Atlantis GitHub Actions PoC
PoC for Atlantis running inside a GitHub Actions Workflow.

This repo demonstrates the possibility of running Atlantis within a GitHub Actions workflow. It uses an external Redis
instance to manage [Atlantis locking](https://www.runatlantis.io/docs/locking.html) (although in this example the Redis
instance is a local one for simplicity), and GitHub Action caches to store plans for each pull request. This implies
that there's a possibility that Terraform plans are lost for a given pull request if the cache disappears, but locks
will remain intact. A simple `atlantis plan` will suffice to generate a new Terraform plan.

See example PR: https://github.com/danielgblanco/atlantis-gha-poc/pull/53

A few caveats of this approach are documented below:

1. Atlantis is not run as a service container (like Redis) to allow the `cache` action to have access to the Atlantis
data dir. It is possible to mount a volume in the service container, but not straight-forward to 
2. If Atlantis could be run as a binary receiving commands instead of a server, the main step could be simplified to
pass the GitHub event triggering the action.
3. GitHub caches are indexed using the given key, and the Git reference of the event that triggered the action. For
issue comments, this is the [last commit on the default branch](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#issue_comment).
This has two side-effects:
   1. The same cache cannot be used to respond to events coming from `pull_request` and `issue_comment` events. This is
   why `pull_request` is disabled and manual `atlantis plan` commands are needed.
   2. Having only `issue_comment` events triggering the build means that the action workflow to be used is the one
   present at the head of the default branch. This means that changes need to be merged for changes to workflows to be
   applied. This could be a positive, as changing the workflow could imply changing Atlantis server side config.
   3. The `pull_request` event is kept as a trigger to allow Atlantis to unlock projects on PR close. The
   `ATLANTIS_DISABLE_AUTOPLAN` option is used to only allow planning and applying (which use cache) via `issue_comment`.
4. No AWS credentials are used in this PoC, but it'd be fairly simple to configure GitHub's OIDC provider with an AWS
IAM Identity Provider endpoint to be able to assume a role (or use AWS key pairs).
5. When `atlantis plan` or `atlantis apply` are executed, there's no immediate feedback in the pull request that those
checks are running for this particular PR (this may already be the case).
6. Due to the nature of GitHub Actions, this workflow has only be considered to run changes in Terraform modules
contained within the same repo (i.e. not accepting events from other repos, or forks).
7. Atlantis container has to be run as root for cache action to have permissions to mounted volume.
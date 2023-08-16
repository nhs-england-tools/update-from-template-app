# TODO

- Specify repository template branch to be used
- Move file operations from the shell script to `cmd/update-from-template`
- Simplify and optmise for speed `cmd/update-from-template` implementation
- Check [actions-template-sync/src/sync_template.sh](https://github.com/AndreasAugustin/actions-template-sync/blob/54cc6daa8773c61a6df312b2cb9f4f82ef72d690/src/sync_template.sh#L35C27-L35C49) implementation
- Update documentation
- Implement ability to run scripts in addition to the update rules
- Implement a feature for this app to run against repositories to be updated from template on schedule or on demand
- Compliance
  - Implement metrics
  - Upload report
- In the action implementation reference image that is already built

## Releasing Changes from the Repository Template into target repositories

1. The changes from the repository template modify the target repository with a fast-forwardable merge commit to the main branch. We want to enable a linear history in the target repository.
2. We do not want to have the full history from the repository template.  We want squashed, atomic commits to a schedule that does not overload the team responsible for the target repository.
3. It is *not* necessary (although it would be preferable) to retain a linear history in the repository template.
4. We need to enable teams to make changes to the applied changeset.
5. If the commit as applied to the target repository breaks their build that is a bug in the commit generation process for us to fix.

# GraphQL Queries

`gh api graphql` is used instead of `gh pr view`/`gh api /repos/.../pulls/.../comments` because REST
does not expose `isOutdated` or `isResolved` on review threads — both are required to filter and
auto-resolve correctly.

## Fetch review threads

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $pr: Int!, $cursor: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100, after: $cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          startLine
          comments(first: 50) {
            nodes {
              id
              body
              author { login }
              createdAt
              url
            }
          }
        }
      }
    }
  }
}' -f owner="<owner>" -f repo="<repo>" -F pr=<number> > /tmp/nit-threads.json
```

Paginate with `-f cursor="<endCursor>"` if `hasNextPage` is `true`. For most PRs one page (100
threads) is enough — check before assuming otherwise.

Each thread's first comment is the original note; later comments are the reply chain. Use the
first comment's body as the primary text for grouping/severity, but read the whole chain — a
later reply sometimes narrows or retracts the original ask.

## Resolve a thread (mutation — requires confirmation)

```bash
gh api graphql -f query='
mutation($threadId: ID!) {
  resolveReviewThread(input: { threadId: $threadId }) {
    thread { id isResolved }
  }
}' -f threadId="<thread node id>"
```

Run once per thread `id` from the fetch query. There is no bulk-resolve mutation — loop over the
confirmed list of thread ids.

## Resolve owner/repo/number from a URL or the current branch

```bash
# From a URL like https://github.com/<owner>/<repo>/pull/<number>
# parse with a plain regex/split — no API call needed

# From the current branch, if no URL was given
gh pr view --json number,url,headRepositoryOwner,headRepository \
  --jq '{number: .number, url: .url}'
```

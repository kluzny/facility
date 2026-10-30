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

## Fetch the PR description, conversation comments and review bodies

This query also returns the PR's `title` and `body` (its description), which Phase 2 reads before
any feedback:

```bash
jq -r '.data.repository.pullRequest | "# \(.title)\n\n\(.body)"' /tmp/nit-comments.json
```

Review threads only cover inline comments. Feedback also lands in top-level PR conversation
comments (`comments`) and in the summary body submitted with a review (`reviews`) — a reviewer
can leave an entire numbered list of findings there with no inline threads at all.

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $pr: Int!, $commentsCursor: String, $reviewsCursor: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      title
      body
      author { login }
      headRefOid
      comments(first: 100, after: $commentsCursor) {
        pageInfo { hasNextPage endCursor }
        nodes { id body author { login } createdAt url isMinimized }
      }
      reviews(first: 100, after: $reviewsCursor) {
        pageInfo { hasNextPage endCursor }
        nodes { id body state author { login } submittedAt url commit { oid } }
      }
    }
  }
}' -f owner="<owner>" -f repo="<repo>" -F pr=<number> > /tmp/nit-comments.json
```

Paginate each connection independently with `-f commentsCursor=...` / `-f reviewsCursor=...`.

Neither connection has `isResolved` or `isOutdated` — these can't be auto-resolved. Most reviews
have an empty body (approvals and inline-only reviews), so drop those. Tag each item with whether
the PR author wrote it — author comments are context (pushback, "done", "won't fix"), not new
feedback:

```bash
jq '.data.repository.pullRequest as $pr | {
  comments: [$pr.comments.nodes[] | select(.isMinimized | not) | .byAuthor = (.author.login == $pr.author.login)],
  reviews:  [$pr.reviews.nodes[]  | select(.body != "")       | .byAuthor = (.author.login == $pr.author.login)]
}' /tmp/nit-comments.json
```

`review.commit.oid` is the commit the review was submitted against; compare it to `headRefOid` to
tell whether the PR has moved on since.

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

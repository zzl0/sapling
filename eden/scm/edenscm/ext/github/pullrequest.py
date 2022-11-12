# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2.

from dataclasses import dataclass
from typing import Any, Dict, TypedDict

from ghstack.github_cli_endpoint import GitHubCLIEndpoint


class PullRequestIdDict(TypedDict):
    owner: str
    name: str
    number: int


@dataclass(eq=True, frozen=True, order=True)
class PullRequestId:
    """A structured representation of the fields used to identify a pull
    request: owner, name, number.
    """

    # In GitHub, a "RepositoryOwner" is either an "Organization" or a "User":
    # https://docs.github.com/en/graphql/reference/interfaces#repositoryowner
    owner: str
    # Name of the GitHub repo within the organization.
    name: str
    # Public-facing integer ID for the pull request.
    number: int

    def as_url(self, domain=None) -> str:
        domain = domain or "github.com"
        return f"https://{domain}/{self.owner}/{self.name}/pull/{self.number}"

    def as_dict(self) -> PullRequestIdDict:
        """Returns this PullRequestId as a Dict that can be serialized as JSON."""
        return {
            "owner": self.owner,
            "name": self.name,
            "number": self.number,
        }


class GraphQLPullRequest:
    """This object represents the information we have about a pull request that
    we got via GitHub's GraphQL API. See the query used by get_pull_request_data()
    in ./graphql.py for the structure of the data.
    """

    def __init__(self, graphql_data_as_dict):
        self.graphql_data = graphql_data_as_dict

    def __getitem__(self, key):
        return self.graphql_data[key]

    def node_id(self) -> str:
        return self.graphql_data["id"]

    def number(self) -> int:
        return self.graphql_data["number"]

    def url(self) -> str:
        return self.graphql_data["url"]

    def get_head_oid(self) -> str:
        return self.graphql_data["headRefOid"]

    def get_head_branch_name(self) -> str:
        return self.graphql_data["headRefName"]


def get_pr_state(github: GitHubCLIEndpoint, pr: PullRequestId) -> Dict[str, Any]:
    query = """
query PullRequestQuery($owner: String!, $name: String!, $number: Int!) {
  repository(name: $name, owner: $owner) {
    pullRequest(number: $number) {
      merged,
      mergeCommit {
        oid
      }
    }
  }
}
"""
    response = github.graphql(query, owner=pr.owner, name=pr.name, number=pr.number)
    pr = response["data"]["repository"]["pullRequest"]
    return {
        "merged": pr["merged"],
        "merge_commit": pr["mergeCommit"]["oid"] if pr["merged"] else None,
    }

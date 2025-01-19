import { DataProvider } from 'react-admin';

export const dataProvider: DataProvider = {
  getList: async (resource, params) => {
    // OpenSearch query implementation
    const { page, perPage } = params.pagination;
    const { field, order } = params.sort;
    const { q, ...filters } = params.filter;

    // TODO: Implement OpenSearch query
    const response = await fetch(`/api/${resource}?page=${page}&perPage=${perPage}`);
    const json = await response.json();

    return {
      data: json.data,
      total: json.total,
    };
  },

  getOne: async (resource, params) => {
    const response = await fetch(`/api/${resource}/${params.id}`);
    const json = await response.json();

    return {
      data: json,
    };
  },

  getMany: async (resource, params) => {
    const response = await fetch(`/api/${resource}?ids=${params.ids.join(',')}`);
    const json = await response.json();

    return {
      data: json,
    };
  },

  getManyReference: async (resource, params) => {
    const { page, perPage } = params.pagination;
    const { field, order } = params.sort;
    
    const response = await fetch(
      `/api/${resource}?target=${params.target}&id=${params.id}&page=${page}&perPage=${perPage}`
    );
    const json = await response.json();

    return {
      data: json.data,
      total: json.total,
    };
  },

  create: async (resource, params) => {
    const response = await fetch(`/api/${resource}`, {
      method: 'POST',
      body: JSON.stringify(params.data),
      headers: {
        'Content-Type': 'application/json',
      },
    });
    const json = await response.json();

    return {
      data: { ...params.data, id: json.id },
    };
  },

  update: async (resource, params) => {
    const response = await fetch(`/api/${resource}/${params.id}`, {
      method: 'PUT',
      body: JSON.stringify(params.data),
      headers: {
        'Content-Type': 'application/json',
      },
    });
    const json = await response.json();

    return {
      data: json,
    };
  },

  updateMany: async (resource, params) => {
    const response = await fetch(`/api/${resource}`, {
      method: 'PUT',
      body: JSON.stringify({ ids: params.ids, data: params.data }),
      headers: {
        'Content-Type': 'application/json',
      },
    });
    const json = await response.json();

    return {
      data: json,
    };
  },

  delete: async (resource, params) => {
    await fetch(`/api/${resource}/${params.id}`, {
      method: 'DELETE',
    });

    return {
      data: params.previousData,
    };
  },

  deleteMany: async (resource, params) => {
    await fetch(`/api/${resource}`, {
      method: 'DELETE',
      body: JSON.stringify({ ids: params.ids }),
      headers: {
        'Content-Type': 'application/json',
      },
    });

    return {
      data: [],
    };
  },
}; 